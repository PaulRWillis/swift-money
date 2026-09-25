#!/usr/bin/env bash
# Check the *public* API of every library product for source-breaking changes against a baseline.
# The same script runs locally and in CI, so a break a reviewer sees in the log is one you can
# reproduce.
#
# Usage:
#   bash APIBreak/check.sh                 # compare against origin/main
#   bash APIBreak/check.sh origin/main     # same, explicit
#   bash APIBreak/check.sh <ref>           # compare against any git ref
#
# Requirements: Swift 6.2+ and jq. The baseline ref must be fetched (CI checks out with
# fetch-depth: 0 so origin/main is present).
#
# Why drive swift-api-digester directly instead of `swift package diagnose-api-breaking-changes`?
# SwiftPM builds every module with -package-name and offers no access-level filter, so its apidiff
# compares the whole ABI, `package` and `internal` decls included. A `package`-only change (for
# example adding a parameter to LocaleNumberFormat's `package init`) then trips the gate as a false
# positive, though no consumer can see it. The usual fix — emit a public `.swiftinterface` under
# library evolution and diff that — is out too: `-enable-library-evolution` does not compile this
# package (a stored `let` in SwiftMoneyCore cannot be initialized directly under resilience).
#
# The lever that works: `swift-api-digester -dump-sdk`, run against the built `.swiftmodule`
# *without* -package-name, marks every `package`/`internal` decl `"isInternal": true` in its JSON
# while genuine `public` decls carry no such flag. So we dump both trees, prune every `isInternal`
# node (and any `@_spi` node, future-proofing) with jq, and only then diff the two public-only trees
# with -diagnose-sdk. What survives the prune is exactly the consumer-facing surface.
#
# The digester takes one -module flag per module and always exits 0, so the gate signal is the count
# of `API breakage:` lines it prints, not its exit status. Rather than hard-code the library targets
# here, where they can silently drift from Package.swift as products are added or renamed, derive
# them from the manifest: every target reachable from a `.library` product, and only those. A new
# library product is then covered the moment it exists, with no edit to this script or the workflow.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

BASELINE="${1:-origin/main}"

# Temp tree for the baseline export and every dump, cleaned by an EXIT trap set in main. Declared
# here so the trap can see it whatever scope it fires from.
WORK=""

# Absolute path to swift-api-digester. On macOS it lives in the active toolchain, found via xcrun;
# on Linux (the CI host) there is no xcrun, so resolve it beside the real swiftc binary.
resolve_digester() {
    if command -v xcrun >/dev/null 2>&1; then
        xcrun -f swift-api-digester
    else
        local swiftc
        swiftc="$(readlink -f "$(command -v swiftc)")"
        echo "$(dirname "$swiftc")/swift-api-digester"
    fi
}

# The compilation target triple the digester must dump for. Read it from the compiler itself so the
# script is not pinned to one architecture or OS version.
target_triple() {
    swift -print-target-info | jq -r '.target.triple'
}

# The SDK flags for dump-sdk, emitted as a whitespace-separated list the caller reads into an array.
# macOS needs an explicit -sdk so Swift/Foundation resolve; on Linux they resolve without one, so the
# list is empty there.
sdk_args() {
    if command -v xcrun >/dev/null 2>&1; then
        echo "-sdk $(xcrun --show-sdk-path)"
    fi
}

# The targets that make up the package's public library surface. A product carries a `type` object
# whose single key names the kind, so `.type | has("library")` selects the libraries and leaves out
# executables and plugins. `.targets[]` are the targets each library exposes; sort -u collapses the
# ones shared between products (SwiftMoneyCore backs three of them).
#
# An empty list means the manifest shape changed under us (a renamed key, a jq version that prints
# nothing) and every following run would check nothing while still passing. Fail here instead, so the
# gap is loud rather than a green check that guards nothing.
derive_targets() {
    local targets=()
    while IFS= read -r target; do
        targets+=("$target")
    done < <(swift package dump-package | jq -r '.products[] | select(.type|has("library")) | .targets[]' | sort -u)

    if [[ ${#targets[@]} -eq 0 ]]; then
        echo "Error: no library-product targets derived from Package.swift" >&2
        exit 1
    fi
    printf '%s\n' "${targets[@]}"
}

# Build the package rooted at $1 and echo the directory to hand the digester with -I. Build output
# goes to stderr so stdout carries only the import directory. The classic SwiftPM layout keeps
# modules in a `Modules` subdirectory (Linux CI); the swiftbuild layout keeps the .swiftmodule files
# in the bin directory itself (macOS), so prefer `Modules` when it exists and fall back to the bin
# directory otherwise.
build_tree() {
    local dir="$1"
    ( cd "$dir" && swift build ) >&2
    local bin
    bin="$( cd "$dir" && swift build --show-bin-path )"
    if [[ -d "$bin/Modules" ]]; then
        echo "$bin/Modules"
    else
        echo "$bin"
    fi
}

# Export the baseline ref into a fresh temp directory and build it there, echoing that build's import
# directory. `git archive | tar -x` gives a clean tree at the ref with no dependence on SwiftPM's
# apidiff checkout plumbing. The directory is registered for trap cleanup by the caller.
prepare_baseline() {
    local ref="$1" dir="$2"
    git archive "$ref" | tar -x -C "$dir"
    build_tree "$dir"
}

# Dump the public API of one module to JSON: run dump-sdk against the built module, then prune with
# jq every node the digester marked `isInternal` (that is, `package`/`internal`) or that carries an
# `@_spi` group, leaving a public-only tree. $1 module, $2 import dir, $3 output path.
dump_public_sdk() {
    local module="$1" import_dir="$2" out="$3"
    local raw="$out.raw"

    # `read` returns non-zero at end of input, which on Linux (where sdk_args is empty) would abort
    # under `set -e`; the `|| true` keeps an empty SDK list from failing the run.
    local sdk_array=()
    read -r -a sdk_array <<<"$(sdk_args)" || true
    "$DIGESTER" -dump-sdk -module "$module" -o "$raw" \
        -I "$import_dir" -target "$TRIPLE" \
        "${sdk_array[@]+"${sdk_array[@]}"}" >&2

    jq 'def prune: if type=="object" then (if has("children") then .children |= [.[] | select((.isInternal // false | not) and (has("spi_group_names") | not)) | prune] else . end) else . end; .ABIRoot |= prune' \
        "$raw" >"$out"
}

# Canary: the number of the module's own declarations that survive the prune. The gate trusts the
# digester to mark `package`/`internal` as `isInternal`; if a toolchain change ever stopped doing so
# in the other direction — marking everything internal — the public tree would collapse to nothing
# and every real break would slip through a silent, empty diff. Reporting this count per target lets
# main assert the surface is non-empty for at least one target and fail loud if it is not.
public_decl_count() {
    local module="$1" json="$2"
    jq --arg m "$module" '[.. | objects | select(has("declKind") and .moduleName==$m)] | length' "$json"
}

# Diff two public-only dumps and print the count of `API breakage:` lines. The digester always exits
# 0, so this count — not the exit status — is the signal. $1 baseline json, $2 current json.
diagnose() {
    local base_json="$1" cur_json="$2"
    local diag
    diag="$("$DIGESTER" -diagnose-sdk -compiler-style-diags \
        -input-paths "$base_json" -input-paths "$cur_json" 2>&1 1>/dev/null || true)"

    if [[ -n "$diag" ]]; then
        grep "API breakage:" <<<"$diag" >&2 || true
    fi
    grep -c "API breakage:" <<<"$diag" || true
}

main() {
    DIGESTER="$(resolve_digester)"
    TRIPLE="$(target_triple)"

    local targets=()
    while IFS= read -r target; do
        targets+=("$target")
    done < <(derive_targets)

    echo "Checking public API breaks for: ${targets[*]}"

    WORK="$(mktemp -d)"
    local baseline_dir="$WORK/baseline"
    mkdir -p "$baseline_dir"
    trap '[[ -n "${WORK:-}" ]] && rm -rf "$WORK"' EXIT

    echo "Building current tree..." >&2
    local cur_import
    cur_import="$(build_tree "$REPO_DIR")"

    echo "Preparing baseline tree at $BASELINE..." >&2
    local base_import
    base_import="$(prepare_baseline "$BASELINE" "$baseline_dir")"

    local total=0 surface=0
    for target in "${targets[@]}"; do
        dump_public_sdk "$target" "$base_import" "$WORK/$target.base.json"
        dump_public_sdk "$target" "$cur_import" "$WORK/$target.cur.json"

        surface=$(( surface + $(public_decl_count "$target" "$WORK/$target.cur.json") ))

        local breaks
        breaks="$(diagnose "$WORK/$target.base.json" "$WORK/$target.cur.json")"
        total=$(( total + breaks ))
    done

    # If nothing public survived the prune across every target, the diff compared empty trees and
    # would pass no matter what changed. Treat that as a broken gate, not a clean run.
    if [[ $surface -eq 0 ]]; then
        echo "Error: no public declarations survived pruning for any target; the gate is guarding nothing" >&2
        exit 1
    fi

    if [[ $total -gt 0 ]]; then
        echo "Found $total public API breakage(s)." >&2
        exit 1
    fi

    echo "No public API breaks."
}

main

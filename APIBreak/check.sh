#!/usr/bin/env bash
# Check the public API of every library product for source-breaking changes against a baseline.
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
# The digester takes one --targets flag per target, so the list of what to check has to be spelled
# out. Rather than hard-code the four library targets in the workflow, where they can silently drift
# from Package.swift as products are added or renamed, derive them from the manifest: every target
# reachable from a `.library` product, and only those. A new library product is then covered the
# moment it exists, with no workflow edit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

BASELINE="${1:-origin/main}"

# The targets that make up the package's public library surface. A product carries a `type` object
# whose single key names the kind, so `.type | has("library")` selects the libraries and leaves out
# executables and plugins. `.targets[]` are the targets each library exposes; sort -u collapses the
# ones shared between products (SwiftMoneyCore backs three of them).
TARGETS=()
while IFS= read -r target; do
    TARGETS+=("$target")
done < <(swift package dump-package | jq -r '.products[] | select(.type|has("library")) | .targets[]' | sort -u)

# An empty list means the manifest shape changed under us (a renamed key, a jq version that prints
# nothing) and every following run would check nothing while still passing. Fail here instead, so the
# gap is loud rather than a green check that guards nothing.
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    echo "Error: no library-product targets derived from Package.swift" >&2
    exit 1
fi

echo "Checking API breaks for: ${TARGETS[*]}"

# The digester wants the targets as repeated --targets flags, so expand the list into the argv array.
TARGET_ARGS=()
for target in "${TARGETS[@]}"; do
    TARGET_ARGS+=(--targets "$target")
done

# Pass the digester's exit status straight through: 0 for no break, non-zero when the public API
# changed. The caller (the workflow's report step non-fatal, its enforce step fatal) decides what to
# do with it.
swift package diagnose-api-breaking-changes "$BASELINE" "${TARGET_ARGS[@]}"

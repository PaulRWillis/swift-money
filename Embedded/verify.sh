#!/usr/bin/env bash
# Verify that SwiftMoneyCore compiles under Embedded Swift.
#
# The core is meant to run on Embedded Swift, which forbids Foundation, existentials, reflection, and
# metatypes. This compiles every core source under the Embedded feature so a change that reaches for one
# of those fails here rather than in a user's firmware build. The Codable surface is excluded from the
# core under Embedded (see the `#if !hasFeature(Embedded)` guards), so it is not exercised here.
#
# Usage:
#   bash Embedded/verify.sh
#
# Requirements: a toolchain whose standard library was built for Embedded Swift. Apple's Xcode toolchain
# does NOT ship one; a swift.org toolchain (e.g. via swiftly) does. The script finds one on PATH or under
# the usual swiftly / swift.org locations, and explains how to get one if it cannot.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# A bare-metal, no-OS triple: the strictest Embedded target, so passing it is the strongest guarantee.
TARGET="arm64-apple-none-macho"
MODULE="SwiftMoneyCore"

# Locates a swiftc whose toolchain carries the Embedded standard library. Prints its path, or nothing.
find_embedded_swiftc() {
    local candidates=()

    # A swiftly-managed toolchain, if the tool is installed.
    if command -v swiftly >/dev/null 2>&1; then
        local location
        location="$(swiftly use --print-location 2>/dev/null || true)"
        [[ -n "$location" ]] && candidates+=("$location/usr/bin/swiftc")
    fi

    # swift.org toolchains installed into the standard directories, newest last.
    local dir
    for dir in "$HOME/Library/Developer/Toolchains"/swift-*.xctoolchain \
               "/Library/Developer/Toolchains"/swift-*.xctoolchain; do
        [[ -d "$dir" ]] && candidates+=("$dir/usr/bin/swiftc")
    done

    # Whatever `swiftc` resolves to, tried last so an explicit toolchain wins.
    command -v swiftc >/dev/null 2>&1 && candidates+=("$(command -v swiftc)")

    local swiftc
    for swiftc in "${candidates[@]}"; do
        [[ -x "$swiftc" ]] || continue
        # The embedded stdlib lives under lib/swift/embedded; only such a toolchain can do this.
        local root
        root="$(cd "$(dirname "$swiftc")/.." && pwd)"
        if [[ -d "$root/lib/swift/embedded/Swift.swiftmodule" ]]; then
            echo "$swiftc"
            return 0
        fi
    done

    return 1
}

SWIFTC="$(find_embedded_swiftc || true)"

if [[ -z "$SWIFTC" ]]; then
    cat >&2 <<'EOF'
error: no toolchain with an Embedded Swift standard library was found.

Apple's Xcode toolchain does not ship one. Install a swift.org toolchain, e.g. with swiftly:

    curl -O https://download.swift.org/swiftly/darwin/swiftly.pkg
    installer -pkg swiftly.pkg -target CurrentUserHomeDirectory
    ~/.swiftly/bin/swiftly init

then re-run this script.
EOF
    exit 1
fi

echo "Embedded toolchain: $SWIFTC"
"$SWIFTC" --version | head -1

# `-package-name` is required because the core uses `package`-level access; `-parse-as-library` because
# there is no top-level entry point; `-wmo` because Embedded Swift always builds whole-module.
SOURCES=()
while IFS= read -r file; do
    SOURCES+=("$file")
done < <(find "$REPO_DIR/Sources/$MODULE" -name '*.swift')

echo "Compiling $MODULE (${#SOURCES[@]} files) for Embedded, target $TARGET..."
# `-c` (emit object), not `-typecheck`: Embedded rejects existentials, metatypes, and the like at code
# generation, so a typecheck alone would pass code that Embedded cannot actually build. The object goes
# to a throwaway directory that is removed on exit.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

"$SWIFTC" -c \
    -enable-experimental-feature Embedded \
    -wmo -parse-as-library \
    -target "$TARGET" \
    -module-name "$MODULE" \
    -package-name "$MODULE" \
    "${SOURCES[@]}" \
    -o "$WORKDIR/$MODULE.o"

echo "OK: $MODULE compiles under Embedded Swift."

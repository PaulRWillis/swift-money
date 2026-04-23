#!/usr/bin/env bash
# Build and optionally run the SwiftMoney libFuzzer fuzz target.
#
# Platform: Linux only — Swift's -sanitize=fuzzer requires the open-source
#           toolchain (not available in Xcode on macOS).
#
# Usage:
#   bash Fuzz/run.sh              # build only (release)
#   bash Fuzz/run.sh run          # build + run (Ctrl-C to stop)
#   bash Fuzz/run.sh run -max_total_time=60  # run for 60 seconds
#   bash Fuzz/run.sh debug        # build only (debug, for lldb)
#   bash Fuzz/run.sh debug run    # build debug + run
#
# Requirements: Swift 6.2+ open-source toolchain on Linux.
#
# Build strategy: The library is compiled WITHOUT sanitizers into a
# .swiftmodule + .o, then the fuzz target is compiled WITH -sanitize=fuzzer
# and linked against the library object. This isolates UBSan instrumentation
# to the fuzz harness, avoiding false positives from well-defined Swift
# integer operations (Int128 decomposition, negation) in the library code.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_DIR/Sources/SwiftMoney"
FUZZ_SRC="$SCRIPT_DIR/SwiftMoneyFuzz.swift"
OUTPUT="$SCRIPT_DIR/fuzz-swiftmoney"
CORPUS_DIR="$SCRIPT_DIR/corpus"
BUILD_DIR="$SCRIPT_DIR/.build"

if [[ "$(uname)" != "Linux" ]]; then
    echo "Error: libFuzzer (-sanitize=fuzzer) requires the open-source Swift toolchain on Linux."
    echo "       It is not available in Xcode on macOS."
    exit 1
fi

# Collect all library sources recursively
LIB_SOURCES=()
while IFS= read -r -d '' f; do
    LIB_SOURCES+=("$f")
done < <(find "$SRC_DIR" -name '*.swift' -print0)

DEBUG=false
if [[ "${1:-}" == "debug" ]]; then
    DEBUG=true
    shift
fi

OPT_FLAGS="-O"
if $DEBUG; then
    OPT_FLAGS="-Onone -g"
    echo "  (debug build with -g -Onone)"
fi

mkdir -p "$BUILD_DIR"

echo "Building library (${#LIB_SOURCES[@]} sources, no sanitizer)..."
# shellcheck disable=SC2086
swiftc \
    -parse-as-library \
    -module-name SwiftMoney \
    -emit-module -emit-module-path "$BUILD_DIR/SwiftMoney.swiftmodule" \
    -emit-object \
    $OPT_FLAGS \
    "${LIB_SOURCES[@]}" \
    -o "$BUILD_DIR/SwiftMoney.o"

echo "Building fuzz target (with -sanitize=fuzzer)..."
# shellcheck disable=SC2086
swiftc \
    -sanitize=fuzzer \
    -parse-as-library \
    -I "$BUILD_DIR" \
    $OPT_FLAGS \
    "$FUZZ_SRC" \
    "$BUILD_DIR/SwiftMoney.o" \
    -o "$OUTPUT"

echo "Built: $OUTPUT"

if [[ "${1:-}" == "run" ]]; then
    shift
    mkdir -p "$CORPUS_DIR"
    echo "Running fuzzer (Ctrl-C to stop)..."
    "$OUTPUT" "$CORPUS_DIR" "$@"
fi

#!/usr/bin/env bash
# Measure SwiftMoney's test coverage. The same script runs locally and in CI, so the numbers a reviewer
# sees are the numbers you can reproduce.
#
# Usage:
#   bash Coverage/run.sh                       # summary
#   bash Coverage/run.sh --diff origin/main    # + coverage of the lines this branch adds
#   bash Coverage/run.sh --skip-tests          # reuse the last run's profile
#   bash Coverage/run.sh --badge               # + write .github/badges/coverage.svg
#   bash Coverage/run.sh --diff origin/main --markdown summary.md
#
# Requirements: Swift 6.2+, python3, and llvm-cov: via xcrun on macOS, on PATH on Linux.
#
# A caveat that matters when reading the output: every trap test uses
# `#expect(processExitsWith: .failure)`, which runs its body in a child process. The child's profile is
# never merged into the parent's, so `preconditionFailure` and the overflow paths guarding it always
# read as uncovered even though they are tested. There are around thirty such tests.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SOURCES="$REPO_DIR/Sources/SwiftMoney"

SKIP_TESTS=false
DIFF_BASE=""
MARKDOWN=""
BADGE=false
BADGE_PATH="$REPO_DIR/.github/badges/coverage.svg"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-tests) SKIP_TESTS=true; shift ;;
        --diff) DIFF_BASE="${2:?--diff needs a ref}"; shift 2 ;;
        --markdown) MARKDOWN="${2:?--markdown needs a file}"; shift 2 ;;
        --badge) BADGE=true; shift ;;
        *) echo "Error: unknown option '$1'" >&2; exit 1 ;;
    esac
done

cd "$REPO_DIR"

# llvm-cov lives inside the Xcode toolchain on macOS, and beside `swift` on Linux, where it is not
# always on PATH, so fall back to resolving the toolchain through the symlink.
llvm_cov() {
    if command -v xcrun >/dev/null 2>&1; then
        xcrun llvm-cov "$@"
    elif command -v llvm-cov >/dev/null 2>&1; then
        llvm-cov "$@"
    else
        "$(dirname "$(readlink -f "$(command -v swift)")")/llvm-cov" "$@"
    fi
}

if ! $SKIP_TESTS; then
    echo "Running tests with coverage..."
    swift test --parallel --enable-code-coverage >/dev/null
fi

# Ask the build system for both paths rather than guessing at a triple. `.build/debug` is a symlink and
# `find` does not follow it, which is how a hardcoded path quietly finds nothing.
BIN_DIR="$(swift build --show-bin-path)"
PROFDATA="$(dirname "$(swift test --enable-code-coverage --show-codecov-path)")/default.profdata"

if [[ ! -f "$PROFDATA" ]]; then
    echo "Error: no coverage profile at $PROFDATA. Run without --skip-tests." >&2
    exit 1
fi

# Exactly one test bundle per configuration. Failing loudly beats picking one arbitrarily, and deriving
# the name beats hardcoding it, which would not survive the rename.
BUNDLE_COUNT="$(find "$BIN_DIR" -maxdepth 1 -name '*.xctest' | wc -l | tr -d ' ')"
if [[ "$BUNDLE_COUNT" != "1" ]]; then
    echo "Error: expected one .xctest bundle in $BIN_DIR, found $BUNDLE_COUNT" >&2
    exit 1
fi

BUNDLE="$(find "$BIN_DIR" -maxdepth 1 -name '*.xctest')"
BUNDLE_NAME="$(basename "$BUNDLE" .xctest)"

# A bundle on Darwin, a bare executable everywhere else.
if [[ -f "$BUNDLE/Contents/MacOS/$BUNDLE_NAME" ]]; then
    TEST_BINARY="$BUNDLE/Contents/MacOS/$BUNDLE_NAME"
else
    TEST_BINARY="$BUNDLE"
fi

# Collect the sources to report on, so the numbers describe the library rather than the whole
# package. The find runs in a process substitution, whose exit status the shell discards, so a
# missing directory would otherwise leave SOURCES empty and llvm-cov would silently report every
# file it knows: the tests and the derived test runner included. That is what a stale path here
# did until 2026-08-20, and the badge published the result.
if [[ ! -d "$TARGET_SOURCES" ]]; then
    echo "Error: no sources at $TARGET_SOURCES" >&2
    exit 1
fi

SOURCES=()
while IFS= read -r -d '' f; do
    SOURCES+=("$f")
done < <(find "$TARGET_SOURCES" -name '*.swift' -print0)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "Error: no Swift files under $TARGET_SOURCES" >&2
    exit 1
fi

echo
SUMMARY="$(llvm_cov report "$TEST_BINARY" -instr-profile "$PROFDATA" "${SOURCES[@]}")"
echo "$SUMMARY"

# `llvm-cov report`'s TOTAL row, in column order: regions, missed, cover, functions, missed, cover,
# lines, missed, cover.
read -r REGIONS FUNCTIONS LINES <<< "$(
    echo "$SUMMARY" | awk '$1 == "TOTAL" { print $4, $7, $10 }'
)"

if [[ -n "$DIFF_BASE" ]]; then
    LCOV="$(mktemp)"
    trap 'rm -f "$LCOV"' EXIT
    llvm_cov export -format=lcov "$TEST_BINARY" -instr-profile "$PROFDATA" "${SOURCES[@]}" > "$LCOV"

    echo
    echo "Coverage of the lines this branch adds, against $DIFF_BASE:"
    echo
    python3 "$SCRIPT_DIR/diff-coverage.py" "$DIFF_BASE" "$LCOV"
fi

if $BADGE; then
    mkdir -p "$(dirname "$BADGE_PATH")"
    python3 "$SCRIPT_DIR/badge.py" "${LINES%\%}" > "$BADGE_PATH"

    echo
    echo "Wrote $BADGE_PATH at $LINES"
fi

if [[ -n "$MARKDOWN" ]]; then
    {
        echo "### Coverage"
        echo
        echo "| | Lines | Functions | Regions |"
        echo "|:--|------:|----------:|--------:|"
        echo "| SwiftMoney | $LINES | $FUNCTIONS | $REGIONS |"
        if [[ -n "$DIFF_BASE" ]]; then
            echo
            python3 "$SCRIPT_DIR/diff-coverage.py" "$DIFF_BASE" "$LCOV" --format markdown
        fi
        echo
        echo "<details><summary>Per file, least covered first</summary>"
        echo
        echo "$SUMMARY" | python3 "$SCRIPT_DIR/report-table.py" --prefix "Sources/SwiftMoney/"
        echo
        echo "</details>"
    } > "$MARKDOWN"

    echo
    echo "Wrote $MARKDOWN"
fi

#!/usr/bin/env bash
# Measure the package's test coverage. The same script runs locally and in CI, so the numbers a reviewer
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
# A trap test uses `#expect(processExitsWith: .failure)`, whose body runs in a child process that then
# traps — so LLVM never flushes that child's coverage counters and the `preconditionFailure` it verifies
# cannot be measured. Those lines, and unreachable defensive branches, carry a `// coverage:ignore`
# marker that `diff-coverage.py` leaves out of the added-line coverage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SOURCES="$REPO_DIR/Sources"

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
    # Serial, not parallel: swift-corelibs-foundation's ICU is not thread-safe under `swift test
    # --parallel` on Linux, which intermittently corrupts formatter output (the same race #199
    # serialised the Thread Sanitizer job around). Coverage does not need the parallelism.
    swift test --no-parallel --enable-code-coverage >/dev/null
fi

# Ask the build system for both paths rather than guessing at a triple. `.build/debug` is a symlink and
# `find` does not follow it, which is how a hardcoded path quietly finds nothing.
BIN_DIR="$(swift build --show-bin-path)"
PROFDATA="$(dirname "$(swift test --enable-code-coverage --show-codecov-path)")/default.profdata"

if [[ ! -f "$PROFDATA" ]]; then
    echo "Error: no coverage profile at $PROFDATA. Run without --skip-tests." >&2
    exit 1
fi

# Collect every test binary the build system produced. Each links the library statically and so carries
# its coverage mapping, so handing llvm-cov all of them and letting it merge the duplicated mappings
# covers the whole library. The shape depends on platform and build system:
#   - macOS: one `.xctest` bundle per test target (swiftbuild) or one merged bundle (native), each
#     wrapping its executable at Contents/MacOS/<name>.
#   - Linux native: a bare `*.xctest` executable file.
#   - Linux swiftbuild: no `.xctest` at all, a bare executable per test target named for the target.
TEST_BINARIES=()
while IFS= read -r -d '' bundle; do
    name="$(basename "$bundle" .xctest)"
    # A bundle on Darwin, a bare executable everywhere else.
    if [[ -f "$bundle/Contents/MacOS/$name" ]]; then
        TEST_BINARIES+=("$bundle/Contents/MacOS/$name")
    else
        TEST_BINARIES+=("$bundle")
    fi
done < <(find "$BIN_DIR" -maxdepth 1 -name '*.xctest' -print0)

# Linux swiftbuild emits no `.xctest`; fall back to the bare test executables. Every test target's name
# contains "test", so this matches them wherever the layout puts them (directly in the products dir or a
# level down) while leaving out the dev-only tool executables (GenerateSwiftMoneyLocalization and friends,
# none of which contain "test") and the linked libraries (`.so`/`.dylib`, some of which do, like
# libXCTest). The exact name and depth of a test binary have moved between toolchains, so this matches on
# the durable signal rather than a fixed name or depth.
if [[ ${#TEST_BINARIES[@]} -eq 0 ]]; then
    while IFS= read -r -d '' binary; do
        TEST_BINARIES+=("$binary")
    done < <(
        find "$BIN_DIR" -maxdepth 3 -type f -perm -u+x -iname '*test*' \
            ! -name '*.so' ! -name '*.so.*' ! -name '*.dylib' -print0
    )
fi

# Failing loudly on none beats a silent empty report. Print the layout so a run that still finds nothing
# shows what the build system actually produced, since the test-binary shape has changed between
# toolchains. If a file's coverage later drops to no-data on a platform, that build system links the
# library dynamically rather than into the test binary: add the library archives or shared objects here.
if [[ ${#TEST_BINARIES[@]} -eq 0 ]]; then
    echo "Error: no test binaries in $BIN_DIR" >&2
    echo "Contents (up to 3 levels deep):" >&2
    find "$BIN_DIR" -maxdepth 3 >&2
    exit 1
fi

# llvm-cov takes the first binary as a positional argument and the rest as repeated -object flags.
COV_OBJECTS=("${TEST_BINARIES[0]}")
for binary in "${TEST_BINARIES[@]:1}"; do
    COV_OBJECTS+=(-object "$binary")
done

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
SUMMARY="$(llvm_cov report "${COV_OBJECTS[@]}" -instr-profile "$PROFDATA" "${SOURCES[@]}")"
echo "$SUMMARY"

# `llvm-cov report`'s TOTAL row, in column order: regions, missed, cover, functions, missed, cover,
# lines, missed, cover.
read -r REGIONS FUNCTIONS LINES <<< "$(
    echo "$SUMMARY" | awk '$1 == "TOTAL" { print $4, $7, $10 }'
)"

if [[ -n "$DIFF_BASE" ]]; then
    LCOV="$(mktemp)"
    trap 'rm -f "$LCOV"' EXIT
    llvm_cov export -format=lcov "${COV_OBJECTS[@]}" -instr-profile "$PROFDATA" "${SOURCES[@]}" > "$LCOV"

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
        echo "| All targets | $LINES | $FUNCTIONS | $REGIONS |"
        if [[ -n "$DIFF_BASE" ]]; then
            echo
            python3 "$SCRIPT_DIR/diff-coverage.py" "$DIFF_BASE" "$LCOV" --format markdown
        fi
        echo
        echo "<details><summary>Per file, least covered first</summary>"
        echo
        echo "$SUMMARY" | python3 "$SCRIPT_DIR/report-table.py" --prefix "Sources/"
        echo
        echo "</details>"
    } > "$MARKDOWN"

    echo
    echo "Wrote $MARKDOWN"
fi

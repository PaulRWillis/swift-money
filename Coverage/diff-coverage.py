#!/usr/bin/env python3
"""Report how well tested the lines a branch adds are.

Intersects the added-line ranges from a git diff with the per-line hit counts in an lcov report. Lines
with no lcov record are not executable, so blank lines, comments and declarations drop out without
needing to be recognised.

Usage:
    python3 Coverage/diff-coverage.py <base-ref> <lcov-file> [--format text|markdown] [--paths <glob>]
"""

import argparse
import os
import re
import subprocess
import sys

HUNK = re.compile(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@")


def added_lines(base, paths):
    """The line numbers this branch adds, per file, from the diff's hunk headers."""
    diff = subprocess.run(
        ["git", "diff", "--unified=0", f"{base}...HEAD", "--", paths],
        capture_output=True,
        text=True,
        check=True,
    ).stdout

    added, path = {}, None

    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            path = line[6:]
            added.setdefault(path, set())
        elif line.startswith("@@") and path:
            match = HUNK.match(line)
            if match:
                start = int(match.group(1))
                count = int(match.group(2) or 1)
                added[path].update(range(start, start + count))

    return added


def hit_counts(lcov, repo):
    """Executable lines and their hit counts, per file, from an lcov report."""
    counts, path = {}, None

    with open(lcov) as report:
        for line in report:
            if line.startswith("SF:"):
                path = os.path.relpath(line[3:].strip(), repo)
                counts.setdefault(path, {})
            elif line.startswith("DA:") and path is not None:
                number, hits = line[3:].strip().split(",")[:2]
                counts[path][int(number)] = int(hits)

    return counts


def measure(base, lcov, paths, repo):
    added = added_lines(base, paths)
    counts = hit_counts(lcov, repo)

    rows, total, covered = [], 0, 0

    for path in sorted(added):
        executable = added[path] & counts.get(path, {}).keys()
        if not executable:
            continue

        missed = sorted(n for n in executable if counts[path][n] == 0)
        hit = len(executable) - len(missed)

        total += len(executable)
        covered += hit
        rows.append((path, hit, len(executable), missed))

    return rows, covered, total


CAVEAT = (
    "Trap tests run their body in a child process, whose profile is never merged, "
    "so `preconditionFailure` and the overflow paths guarding it read as uncovered."
)


def as_text(rows, covered, total):
    for path, hit, count, missed in rows:
        note = f"  missed {','.join(map(str, missed))}" if missed else ""
        print(f"  {path:<52} {hit:>4}/{count:<4} {100.0 * hit / count:5.1f}%{note}")

    if total:
        print(f"\n  lines added: {covered}/{total} covered = {100.0 * covered / total:.1f}%")
        if any(missed for *_, missed in rows):
            print(f"\n  Note: {CAVEAT}")
    else:
        print("  no executable lines added")


def as_markdown(rows, covered, total):
    if not total:
        print("_This branch adds no executable lines._")
        return

    print(f"**Coverage of added lines: {covered}/{total} = {100.0 * covered / total:.1f}%**\n")
    print("| File | Covered | | Uncovered lines |")
    print("|:-----|--------:|----:|:----------------|")

    for path, hit, count, missed in rows:
        lines = ", ".join(map(str, missed)) if missed else "—"
        print(f"| `{path}` | {hit}/{count} | {100.0 * hit / count:.1f}% | {lines} |")

    if any(missed for *_, missed in rows):
        print(f"\n> {CAVEAT}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", help="the ref to diff against, such as origin/main")
    parser.add_argument("lcov", help="an lcov report from llvm-cov export")
    parser.add_argument("--format", choices=["text", "markdown"], default="text")
    parser.add_argument("--paths", default="Sources/*.swift", help="pathspec limiting the diff")
    args = parser.parse_args()

    repo = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
    ).stdout.strip()

    rows, covered, total = measure(args.base, args.lcov, args.paths, repo)

    if args.format == "markdown":
        as_markdown(rows, covered, total)
    else:
        as_text(rows, covered, total)


if __name__ == "__main__":
    sys.exit(main())

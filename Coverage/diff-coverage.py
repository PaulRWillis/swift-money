#!/usr/bin/env python3
"""Report how well tested the lines a branch adds are.

Intersects the added-line ranges from a git diff with the per-line hit counts in an lcov report. Lines
with no lcov record are not executable, so blank lines, comments and declarations drop out without
needing to be recognized. A line tagged `// coverage:ignore` is excluded too — see `ignored_lines`.

Usage:
    python3 Coverage/diff-coverage.py <base-ref> <lcov-file> [--format text|markdown] [--paths <glob>]
"""

import argparse
import os
import re
import subprocess
import sys

HUNK = re.compile(r"@@ -\S+ \+(\d+)(?:,(\d+))? @@")

# A line carrying this marker is left out of the coverage numbers: a trap path an exit test verifies but
# a crashing process can never flush counters for, or an unreachable defensive branch. Keep the marker
# on the same line as the code it excuses.
IGNORE_MARKER = "// coverage:ignore"


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


def ignored_lines(paths, repo):
    """Line numbers tagged `// coverage:ignore`, per file."""
    ignored = {}

    for path in paths:
        try:
            with open(os.path.join(repo, path)) as source:
                ignored[path] = {
                    number for number, text in enumerate(source, start=1) if IGNORE_MARKER in text
                }
        except OSError:
            ignored[path] = set()

    return ignored


def measure(base, lcov, paths, repo):
    added = added_lines(base, paths)
    counts = hit_counts(lcov, repo)
    ignored = ignored_lines(added.keys(), repo)

    rows, total, covered, excluded = [], 0, 0, 0

    for path in sorted(added):
        executable = added[path] & counts.get(path, {}).keys()

        skipped = executable & ignored.get(path, set())
        excluded += len(skipped)
        executable -= skipped

        if not executable:
            continue

        missed = sorted(n for n in executable if counts[path][n] == 0)
        hit = len(executable) - len(missed)

        total += len(executable)
        covered += hit
        rows.append((path, hit, len(executable), missed))

    return rows, covered, total, excluded


def excluded_note(excluded):
    if not excluded:
        return None

    plural = "s" if excluded != 1 else ""
    return f"{excluded} added line{plural} excluded via `// coverage:ignore`"


def as_text(rows, covered, total, excluded):
    for path, hit, count, missed in rows:
        note = f"  missed {','.join(map(str, missed))}" if missed else ""
        print(f"  {path:<52} {hit:>4}/{count:<4} {100.0 * hit / count:5.1f}%{note}")

    if total:
        print(f"\n  lines added: {covered}/{total} covered = {100.0 * covered / total:.1f}%")
    elif not excluded:
        print("  no executable lines added")

    note = excluded_note(excluded)
    if note:
        print(f"\n  {note}.")


def as_markdown(rows, covered, total, excluded):
    note = excluded_note(excluded)

    if not total:
        print("_This branch adds no executable lines._")
        if note:
            print(f"\n> {note}.")
        return

    print(f"**Coverage of added lines: {covered}/{total} = {100.0 * covered / total:.1f}%**\n")
    print("| File | Covered | | Uncovered lines |")
    print("|:-----|--------:|----:|:----------------|")

    for path, hit, count, missed in rows:
        lines = ", ".join(map(str, missed)) if missed else "n/a"
        print(f"| `{path}` | {hit}/{count} | {100.0 * hit / count:.1f}% | {lines} |")

    if note:
        print(f"\n> {note}.")


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

    rows, covered, total, excluded = measure(args.base, args.lcov, args.paths, repo)

    if args.format == "markdown":
        as_markdown(rows, covered, total, excluded)
    else:
        as_text(rows, covered, total, excluded)


if __name__ == "__main__":
    sys.exit(main())

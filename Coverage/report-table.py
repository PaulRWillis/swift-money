#!/usr/bin/env python3
"""Turn `llvm-cov report` output into a markdown table, least covered first.

The raw report is thirteen fixed-width columns of full paths, which a pull request comment renders as
lines far too long to read without scrolling sideways. This keeps the three percentages and the count
of missed lines, which is what a reviewer acts on, and drops the path prefix every row shares.

Usage:
    llvm-cov report ... | python3 Coverage/report-table.py --prefix Sources/SwiftMoney/
"""

import argparse
import sys

# `llvm-cov report` column order: filename, regions, missed regions, cover, functions, missed
# functions, executed, lines, missed lines, cover, branches, missed branches, cover.
NAME, REGION_COVER, FUNCTION_COVER, MISSED_LINES, LINE_COVER = 0, 3, 6, 8, 9


def rows(text, prefix):
    for line in text.splitlines():
        fields = line.split()

        if len(fields) < 10 or fields[NAME] in ("Filename",) or set(fields[NAME]) == {"-"}:
            continue

        yield {
            "name": fields[NAME].removeprefix(prefix),
            "lines": fields[LINE_COVER],
            "missed": fields[MISSED_LINES],
            "functions": fields[FUNCTION_COVER],
            "regions": fields[REGION_COVER],
            "is_total": fields[NAME] == "TOTAL",
        }


def percentage(value):
    try:
        return float(value.rstrip("%"))
    except ValueError:
        return 100.0


def table(measured):
    files = sorted((r for r in measured if not r["is_total"]), key=lambda r: percentage(r["lines"]))
    totals = [r for r in measured if r["is_total"]]

    lines = [
        "| File | Lines | Missed | Functions | Regions |",
        "|:--|--:|--:|--:|--:|",
    ]

    for row in files:
        lines.append(
            f"| {row['name']} | {row['lines']} | {row['missed']} | "
            f"{row['functions']} | {row['regions']} |"
        )

    for row in totals:
        lines.append(
            f"| **Total** | **{row['lines']}** | **{row['missed']}** | "
            f"**{row['functions']}** | **{row['regions']}** |"
        )

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prefix", default="", help="a path prefix to drop from every filename")
    arguments = parser.parse_args()

    print(table(list(rows(sys.stdin.read(), arguments.prefix))))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Fold a benchmark run's markdown tables into BENCHMARKS.md.

Two things go in, between marker comments the document already carries: the raw per-benchmark tables,
and a summary pairing each operation against the alternative it is competing with.

Usage:
    swift package --package-path Benchmarks benchmark run --format markdown --path stdout \
        > results.md
    python3 Benchmarks/summarise.py results.md BENCHMARKS.md

Lives here rather than inside the workflow so that it can be run and read on a laptop. It was 131 lines
of Python inside a YAML string, which is why its pairing table had drifted out of step with the
benchmarks without anyone noticing.
"""

import argparse
import re
import sys

# One section per benchmark: a heading, then a table whose rows are metrics.
#
# The whole table is captured and split afterwards, rather than matching a fixed number of rows. The
# previous form matched exactly four `(\|.+?\|)` groups, which broke twice over: the last group had no
# following newline to anchor it, so a lazy `.+?` stopped at the second pipe and truncated the row it
# needed most; and four groups only ever fit a two-metric benchmark.
SECTION = re.compile(r"### (.+?)\n\n((?:\|[^\n]*\n?)+)")

RAW_MARKERS = ("<!-- BENCHMARK-START -->", "<!-- BENCHMARK-END -->")
SUMMARY_MARKERS = ("<!-- BENCHMARK-SUMMARY-START -->", "<!-- BENCHMARK-SUMMARY-END -->")

# Each row is one line of the summary: a label, the benchmark measuring our implementation, and the
# benchmark it is measured against. A `None` comparison means there is nothing to compare it with.
COMPARISONS = [
    ("Addition", "Money addition", "Foundation Decimal addition"),
    ("Subtraction", "Money subtraction", "Foundation Decimal subtraction"),
    ("Multiplication", "Money multiplication (Int64)", "Foundation Decimal multiplication"),
    ("Comparison", "Money comparison", "Foundation Decimal comparison"),
    ("JSON encode", "Money JSON encode (.minorUnits)", "Foundation Decimal JSON encode"),
    ("JSON decode", "Money JSON decode (.minorUnits)", "Foundation Decimal JSON decode"),
    ("Formatting", "Money formatted()", "Foundation Decimal formatted(.currency)"),
    ("Distribution", "Money distributed(into: 3)", None),
    ("Exchange rate", "ExchangeRate convert", None),
    ("MoneyBag (10 adds)", "MoneyBag add 10 entries", None),
]


def parse(raw):
    """The p50 wall-clock time and malloc count for each benchmark in a markdown run."""
    results = {}

    for section in SECTION.finditer(raw):
        name = section.group(1).strip()
        time_ns, mallocs = None, None

        for row in section.group(2).splitlines():
            columns = [c.strip() for c in row.split("|") if c.strip()]
            if len(columns) < 4:
                continue

            metric = columns[0].replace(" *", "").strip()
            try:
                p50 = int(columns[3].replace(",", ""))
            except ValueError:
                continue

            if "Time" in metric or "wall clock" in metric:
                time_ns = p50
            elif "Malloc" in metric or "malloc" in metric:
                mallocs = p50

        if time_ns is not None:
            results[name] = {"time_ns": time_ns, "mallocs": mallocs or 0}

    return results


def duration(nanoseconds):
    # A p50 of zero means the operation is below the timer's resolution, not that it is free.
    return f"{nanoseconds} ns" if nanoseconds > 0 else "<1 ns"


def speedup(ours, theirs):
    if ours == 0:
        return "**∞**"
    ratio = theirs / ours
    return f"**{ratio:.0f}×**" if ratio >= 1 else f"{ratio:.1f}×"


def summarise(results, warn):
    """A markdown summary, and a warning for every benchmark named here but missing from the run."""
    named = {name for _, ours, theirs in COMPARISONS for name in (ours, theirs) if name}
    for name in sorted(named - results.keys()):
        warn(f"no benchmark named {name!r} in this run — the summary will omit it")

    lines = ["| Operation | Ours | Compared with | Speedup | Our allocs | Their allocs |",
             "|:----------|-----:|--------------:|--------:|-----------:|-------------:|"]

    for label, ours_name, theirs_name in COMPARISONS:
        ours = results.get(ours_name)
        if not ours:
            continue

        theirs = results.get(theirs_name) if theirs_name else None

        if theirs:
            lines.append(
                f"| {label} | {duration(ours['time_ns'])} | {duration(theirs['time_ns'])} "
                f"| {speedup(ours['time_ns'], theirs['time_ns'])} "
                f"| {ours['mallocs']} | {theirs['mallocs']} |"
            )
        else:
            lines.append(
                f"| {label} | {duration(ours['time_ns'])} | — | — | {ours['mallocs']} | — |"
            )

    return "\n".join(lines)


def inject(document, markers, content, warn):
    """Replace whatever sits between a pair of marker comments."""
    start, end = markers
    start_index, end_index = document.find(start), document.find(end)

    if start_index == -1 or end_index == -1:
        warn(f"markers {start} / {end} not found — leaving that section alone")
        return document

    return document[: start_index + len(start)] + "\n" + content + "\n" + document[end_index:]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("results", help="a markdown benchmark run")
    parser.add_argument("document", help="the file to fold the results into")
    args = parser.parse_args()

    warnings = []

    def warn(message):
        warnings.append(message)
        print(f"warning: {message}", file=sys.stderr)

    with open(args.results) as results_file:
        raw = results_file.read()

    if not raw.strip():
        print("No benchmark results to fold in.", file=sys.stderr)
        return 0

    with open(args.document) as document_file:
        document = document_file.read()

    results = parse(raw)
    if not results:
        warn("no benchmarks parsed out of the results — has the output format changed?")

    document = inject(document, RAW_MARKERS, raw, warn)
    document = inject(document, SUMMARY_MARKERS, summarise(results, warn), warn)

    with open(args.document, "w") as document_file:
        document_file.write(document)

    print(f"Folded {len(results)} benchmarks into {args.document}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

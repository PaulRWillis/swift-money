#!/usr/bin/env python3
"""Fold a benchmark run's markdown tables into BENCHMARKS.md.

Two things go in, between marker comments the document already carries: the raw per-benchmark tables,
and a summary pairing each operation against the alternative it is competing with.

`BENCHMARKS.md` lives on the orphan `assets` branch, so fetch a copy before folding into it:

    git show origin/assets:BENCHMARKS.md > BENCHMARKS.md
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

# Each table names its baseline columns once, then lists rows of (label, our benchmark, the benchmarks
# it is measured against — one per column). A table with no columns is a plain list of measurements.
TABLES = [
    {
        "heading": "SwiftMoney against the alternatives",
        "columns": ["Int", "Double", "Decimal"],
        "rows": [
            ("Addition", "MoneyOf addition",
             ["Int addition", "Double addition", "Decimal addition"]),
            ("Subtraction", "MoneyOf subtraction",
             ["Int subtraction", "Double subtraction", "Decimal subtraction"]),
            ("Scalar multiplication", "MoneyOf scalar multiplication",
             ["Int scalar multiplication", "Double scalar multiplication",
              "Decimal scalar multiplication"]),
            ("Scale and round", "MoneyOf scaled and rounded",
             ["Int scaled, truncating", "Double scaled and rounded", "Decimal scaled and rounded"]),
            ("Comparison", "MoneyOf comparison",
             ["Int comparison", "Double comparison", "Decimal comparison"]),
            ("Split into 3", "MoneyOf split into 3",
             ["Int quotient and remainder", "Double divided by 3", "Decimal divided by 3"]),
            ("Chained scaling", "MoneyOf unrounded chain",
             ["Int chained scaling, truncating", "Double chained scaling",
              "Decimal chained scaling"]),
        ],
    },
    {
        "heading": "What the measurement itself costs",
        "columns": [],
        "rows": [
            ("Handing an integer to the harness", "Harness floor, an integer", []),
            ("Handing a struct to the harness", "Harness floor, a struct", []),
        ],
    },
    {
        "heading": "SwiftMoney's own operations",
        "columns": [],
        "rows": [
            ("Addition, throwing", "Money addition, throwing", []),
            ("Scale, reporting a remainder", "MoneyOf scaled, reporting a remainder", []),
            ("Scale, leaving it unrounded", "MoneyOf unrounded scaling", []),
            ("Unrounded addition", "MoneyOf unrounded addition", []),
            ("Chained scaling, rounding each step", "MoneyOf chain, rounding each step", []),
            ("Ratio construction", "Ratio construction", []),
            ("Split into 3, runtime currency", "Money split into 3", []),
            ("Split, iterating the parts", "MoneyOf split, iterating the parts", []),
            ("Total of 10", "MoneyOf total of 10", []),
            ("Currency code validation", "CurrencyCode validation", []),
            ("Proportion", "MoneyOf proportion", []),
            ("Proportion of large amounts", "MoneyOf proportion of large amounts", []),
            ("Addition, separately built currencies", "Money addition, separately built currencies", []),
        ],
    },
]


TIME_SCALES = {"ns": 1, "μs": 1_000, "us": 1_000, "ms": 1_000_000, "s": 1_000_000_000}


def unit(metric):
    """The unit named in a metric heading, such as `ns` in `Time (wall clock) (ns)`."""
    units = re.findall(r"\(([^)]+)\)", metric)

    return units[-1] if units and units[-1] in TIME_SCALES else "ns"


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
                # The table rescales large values and says so in the metric name, so a benchmark
                # slow enough to be reported in microseconds would otherwise be published as
                # nanoseconds, understating it a thousandfold.
                time_ns = p50 * TIME_SCALES[unit(metric)]
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


def cell(measurement):
    """A time, with the allocation count alongside it when there is one to report."""
    if not measurement:
        return "—"
    allocations = measurement["mallocs"]
    if allocations:
        noun = "alloc" if allocations == 1 else "allocs"
        return f"{duration(measurement['time_ns'])} ({allocations} {noun})"
    return duration(measurement["time_ns"])


def table(spec, results):
    # A table whose benchmarks have all gone would otherwise render as a heading over empty columns.
    if not any(results.get(ours) for _, ours, _ in spec["rows"]):
        return []

    columns = spec["columns"]
    headings = ["Operation", "Ours", *columns]

    # A speedup only means something against a single baseline.
    if len(columns) == 1:
        headings.append("Speedup")

    lines = [
        f"### {spec['heading']}",
        "",
        "| " + " | ".join(headings) + " |",
        "|:" + "----------|" + "".join("----------:|" for _ in headings[1:]),
    ]

    for label, ours_name, baseline_names in spec["rows"]:
        ours = results.get(ours_name)
        if not ours:
            continue

        baselines = [results.get(name) for name in baseline_names]
        cells = [label, cell(ours)]
        cells += [cell(b) for b in baselines]
        cells += [""] * (len(columns) - len(baselines))

        if len(columns) == 1:
            only = baselines[0] if baselines else None
            cells.append(speedup(ours["time_ns"], only["time_ns"]) if only else "—")

        lines.append("| " + " | ".join(c or "—" for c in cells) + " |")

    return "\n".join(lines)


def summarise(results, warn):
    """A markdown summary, and a warning for every benchmark named here but missing from the run."""
    named = {
        name
        for spec in TABLES
        for _, ours, baselines in spec["rows"]
        for name in [ours, *baselines]
    }
    for name in sorted(named - results.keys()):
        warn(f"no benchmark named {name!r} in this run — the summary will omit it")

    return "\n\n".join(table(spec, results) for spec in TABLES)


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

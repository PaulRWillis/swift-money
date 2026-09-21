#!/usr/bin/env python3
"""Fold a benchmark run's markdown tables into BENCHMARKS.md.

Two things go in, between marker comments the document already carries: the raw per-benchmark tables,
and a summary pairing each operation against the alternative it is competing with.

`BENCHMARKS.md` lives on the orphan `assets` branch, so fetch a copy before folding into it:

    git show origin/assets:BENCHMARKS.md > BENCHMARKS.md
    swift package --package-path Benchmarks benchmark run --format markdown --path stdout \
        > results.md
    python3 Benchmarks/summarize.py results.md BENCHMARKS.md

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
# it is measured against, one per column). A table with no columns is a plain list of measurements.
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
        # One row per formatting option, each against the Foundation setting that means the same thing.
        # A row's own name carries the path it runs: `[engine]` renders without ICU, `[ICU fallback]`
        # hands the work to Foundation because the option is one the engine does not express. The
        # rounding increment has no Foundation column: Foundation counts it in whole units and ignores
        # it entirely beside a pinned fraction length, so there is nothing equivalent to compare.
        "heading": "Formatting, option by option, against Foundation",
        "columns": ["Decimal"],
        "rows": [
            ("Default", "MoneyOf format, default, en_GB [engine]",
             ["Decimal format, default, en_GB [ICU]"]),
            ("Runtime currency", "Money format, default, en_GB [engine]",
             ["Decimal format, default, en_GB [ICU]"]),
            ("ISO code", "MoneyOf format, ISO code, en_GB [engine]",
             ["Decimal format, ISO code, en_GB [ICU]"]),
            ("Narrow symbol", "MoneyOf format, narrow, en_GB [engine]",
             ["Decimal format, narrow, en_GB [ICU]"]),
            ("Full name", "MoneyOf format, full name, en_GB [engine]",
             ["Decimal format, full name, en_GB [ICU]"]),
            ("Sign, never", "MoneyOf format, sign never, en_GB [engine]",
             ["Decimal format, sign never, en_GB [ICU]"]),
            ("Sign, always", "MoneyOf format, sign always, en_GB [engine]",
             ["Decimal format, sign always, en_GB [ICU]"]),
            ("Sign, accounting", "MoneyOf format, sign accounting, en_GB [engine]",
             ["Decimal format, sign accounting, en_GB [ICU]"]),
            ("Grouping, never", "MoneyOf format, grouping never, en_GB [engine]",
             ["Decimal format, grouping never, en_GB [ICU]"]),
            ("Decimal separator, always", "MoneyOf format, separator always, en_GB [engine]",
             ["Decimal format, separator always, en_GB [ICU]"]),
            ("Precision, 2dp", "MoneyOf format, precision 2dp, en_GB [engine]",
             ["Decimal format, precision 2dp, en_GB [ICU]"]),
            ("Precision, 1dp", "MoneyOf format, precision 1dp, en_GB [engine]",
             ["Decimal format, precision 1dp, en_GB [ICU]"]),
            ("Precision and accounting", "MoneyOf format, precision 1dp and accounting, en_GB [engine]",
             ["Decimal format, precision 1dp and accounting, en_GB [ICU]"]),
            ("Every option", "MoneyOf format, every option, en_GB [engine]",
             ["Decimal format, every option, en_GB [ICU]"]),
            ("Rounding increment", "MoneyOf format, increment, en_GB [ICU fallback]", []),
            ("Attributed", "MoneyOf attributed, default, en_GB [engine]",
             ["Decimal attributed, default, en_GB [ICU]"]),
            ("Parse", "MoneyOf parse, en_GB [ICU]", ["Decimal parse, en_GB [ICU]"]),
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

# The harness reports a large count in thousands or millions and says which in the metric name.
COUNT_SCALES = {"": 1, "K": 1_000, "M": 1_000_000}


def unit(metric, scales=None):
    """The unit named in a metric heading, such as `ns` in `Time (wall clock) (ns)`."""
    scales = TIME_SCALES if scales is None else scales
    units = re.findall(r"\(([^)]+)\)", metric)
    default = "ns" if scales is TIME_SCALES else ""

    return units[-1] if units and units[-1] in scales else default


def parse(raw):
    """The p50 instruction count, wall-clock time and malloc count for each benchmark in a run."""
    results = {}

    for section in SECTION.finditer(raw):
        name = section.group(1).strip()
        time_ns, mallocs, instructions = None, None, None

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
            elif "Instructions" in metric:
                # Rescaled and named the same way the time is, so a benchmark reported in thousands
                # would otherwise read as that many single instructions.
                instructions = p50 * COUNT_SCALES[unit(metric, COUNT_SCALES)]

        if time_ns is not None:
            results[name] = {
                "time_ns": time_ns,
                "mallocs": mallocs or 0,
                "instructions": instructions or 0,
            }

    return results


def duration(nanoseconds):
    # A p50 of zero means the operation is below the timer's resolution, not that it is free.
    return f"{nanoseconds} ns" if nanoseconds > 0 else "<1 ns"


def speedup(ours, theirs):
    """How many times cheaper ours is, counted in instructions.

    Instructions rather than elapsed time, because a runner's wall clock varies by 5% to 16% between
    identical runs and the slowest rows here fit only one sample, which moved a published ratio by
    twice between runs. An instruction count is the same number every time.
    """
    if ours == 0:
        return "**∞**"
    ratio = theirs / ours
    return f"**{ratio:.1f}×**" if ratio >= 1 else f"{ratio:.1f}×"


def count(instructions):
    """An instruction count, in thousands once it runs past four figures."""
    if instructions >= 10_000:
        return f"{instructions / 1_000:.0f}K"
    return f"{instructions}"


def cell(measurement):
    """An instruction count and, alongside it, the allocations and the time it took.

    The instruction count leads because it is the metric the comparison is drawn from, and a reader
    can then check a ratio against the two numbers beside it rather than having to trust it.
    """
    if not measurement:
        return "n/a"

    allocations = measurement["mallocs"]
    parts = [f"{count(measurement['instructions'])} instr"]

    # An operation that allocates nothing says so by leaving the count out, since most do not.
    if allocations:
        parts.append(f"{allocations} {'alloc' if allocations == 1 else 'allocs'}")

    parts.append(duration(measurement["time_ns"]))

    return ", ".join(parts)


def table(spec, results):
    # A table whose benchmarks have all gone would otherwise render as a heading over empty columns.
    # Empty text rather than an empty list, because the caller joins these into one document: a list
    # here stopped a filtered run, which holds the rows of one table and none of the others, from
    # folding at all.
    if not any(results.get(ours) for _, ours, _ in spec["rows"]):
        return ""

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
            cells.append(speedup(ours["instructions"], only["instructions"]) if only else "n/a")

        lines.append("| " + " | ".join(c or "n/a" for c in cells) + " |")

    return "\n".join(lines)


def summarize(results, warn):
    """A markdown summary, and a warning for every benchmark named here but missing from the run."""
    named = {
        name
        for spec in TABLES
        for _, ours, baselines in spec["rows"]
        for name in [ours, *baselines]
    }
    for name in sorted(named - results.keys()):
        warn(f"no benchmark named {name!r} in this run, so the summary will omit it")

    return "\n\n".join(table(spec, results) for spec in TABLES)


def inject(document, markers, content, warn):
    """Replace whatever sits between a pair of marker comments."""
    start, end = markers
    start_index, end_index = document.find(start), document.find(end)

    if start_index == -1 or end_index == -1:
        warn(f"markers {start} / {end} not found, so that section stays unchanged")
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
        warn("no benchmarks parsed out of the results. Has the output format changed?")

    document = inject(document, RAW_MARKERS, raw, warn)
    document = inject(document, SUMMARY_MARKERS, summarize(results, warn), warn)

    with open(args.document, "w") as document_file:
        document_file.write(document)

    print(f"Folded {len(results)} benchmarks into {args.document}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Build the benchmark delta PR comment from every shard's comparison against main.

Each shard of the delta workflow uploads an artifact holding two files: `shard_comparison.md`, the
markdown `benchmark baseline check` printed, and `shard_status.txt`, the verdict the workflow read off
the tool's stderr. This reads every downloaded artifact and prints one comment body that says which
benchmarks regressed and which improved:

    python3 Benchmarks/delta_comment.py shards --job-result success --run-url <url> > comment_body.md

A pull request without the label that turns the comparison on gets a short note saying how to:

    python3 Benchmarks/delta_comment.py --not-run run-benchmarks > comment_body.md

Direction comes from the comparison file, not the status. The status is one word per shard, and a
regression outranks an improvement in it, so a shard that did both reads as a plain regression. In the
file, every group of deviation tables is followed by a verdict line saying whether that group is
BETTER or WORSE than main, which is what each benchmark is filed under here. The status is still
checked against the file, and a shard where the two disagree is reported as failed rather than trusted.

Not every flagged benchmark is reported as a change. The tool flags a wall-clock time as soon as any one
percentile crosses its threshold, and on a shared runner the cheapest benchmarks do that on noise alone.
So a wall-clock deviation counts only when p25, p50 and p75 all cross, in the same direction. The rest
are set aside as noise: counted in the comment and folded away with their tables, but kept out of the
headline and the lists. Allocation and instruction counts are exact, so they count on any percentile.

Lives here rather than inside the workflow so that it can be run and read on a laptop, and tested. The
shell it replaced listed every flagged benchmark as one undifferentiated list under a "regressed"
headline, even when most of them had improved.

    python3 Benchmarks/delta_comment.py --selftest    # verify the parser and every comment shape
"""

import argparse
import re
import sys
import tempfile
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

MARKER = "<!-- benchmark-delta -->"
STATUS_FILE = "shard_status.txt"
COMPARISON_FILE = "shard_comparison.md"

# The heading the tool prints above each benchmark's tables, fenced in markdown output:
#
#     ```
#     ====================================================
#     Threshold deviations for SwiftMoneyBenchmarks:<name>
#     ====================================================
#     ```
HEADING = re.compile(r"^(?:```\n=+\n)?Threshold deviations for [^:\n]+:(?P<benchmark>[^\n]+)$", re.M)

# The line that closes a group of tables. The capture is the word Direction is keyed on.
VERDICT = re.compile(r"^New baseline '[^'\n]+' is (BETTER|WORSE) than the '[^'\n]+' baseline thresholds\.$", re.M)

# The whole of a shard's file when nothing crossed a threshold.
WITHIN_VERDICT = re.compile(r"^New baseline '[^'\n]+' is WITHIN the '[^'\n]+' baseline thresholds\.$", re.M)

# The header of one metric's table under a heading. The metric is followed by its unit and by `%` for a
# relative threshold or `Δ` for an absolute one, and its own name can hold parentheses:
#
#     | Malloc (total) (K, Δ)                    |            main |    pull_request |    Difference Δ |     Threshold Δ |
TABLE_HEADER = re.compile(r"^\| (?P<metric>[^|\n]+?) \([^,()|\n]*, (?:%|Δ)\) *\|[^\n]*\|$", re.M)

# The markdown line between a table's header and its rows.
TABLE_RULE = re.compile(r"^\|:?-+\|")

# One percentile's row: main's value, the pull request's, the difference and the threshold it crossed.
TABLE_ROW = re.compile(
    r"^\| (?P<percentile>\S+) *"
    r"\| *(?P<main>-?\d+) *\| *(?P<pull_request>-?\d+) *\| *(?P<difference>-?\d+) *\| *(?P<threshold>-?\d+) *\|$"
)


class Direction(Enum):
    """Which way a benchmark moved past its threshold, keyed on the word in the tool's verdict line."""

    REGRESSED = "WORSE"
    IMPROVED = "BETTER"


class Percentile(Enum):
    """A percentile the tool can judge a threshold at, as it labels the row."""

    P0 = "p0"
    P25 = "p25"
    P50 = "p50"
    P75 = "p75"
    P90 = "p90"
    P99 = "p99"
    P100 = "p100"


# The percentiles the wall-clock thresholds are set on (`defaultThresholds` in SwiftMoneyBenchmarks.swift).
# A timed metric's deviation counts only when every one of them crossed.
CENTRAL_PERCENTILES = frozenset({Percentile.P25, Percentile.P50, Percentile.P75})


class Measurement(Enum):
    """How a metric is measured, which decides how much a single crossed percentile is worth."""

    # Read off a clock on a runner shared with other jobs, where one percentile can cross on noise alone.
    TIMED = "timed"
    # Counted exactly, so any crossing is a real change.
    COUNTED = "counted"


class Metric(Enum):
    """A metric whose threshold deviations this script knows how to judge, keyed on the tool's table title.

    These are the metrics the benchmarks measure: wall clock and allocations carry thresholds, and
    instructions falls back to the tool's default ones. Any other title is a format error, so that a new
    metric is judged on purpose rather than by accident.
    """

    WALL_CLOCK = "Time (wall clock)"
    MALLOC_TOTAL = "Malloc (total)"
    INSTRUCTIONS = "Instructions"

    @property
    def measurement(self):
        match self:
            case Metric.WALL_CLOCK:
                return Measurement.TIMED
            case Metric.MALLOC_TOTAL | Metric.INSTRUCTIONS:
                return Measurement.COUNTED


class Significance(Enum):
    """Whether a deviation is a change worth reporting or runner noise to set aside."""

    SIGNIFICANT = "significant"
    NOISE = "noise"


@dataclass(frozen=True)
class Row:
    """One percentile of one metric that crossed its threshold, with the numbers as the tool printed them.

    The difference is signed so that positive is worse, whatever the metric's polarity, and is a
    percentage for a relative threshold and a count in the table's unit for an absolute one.
    """

    percentile: Percentile
    main: int
    pull_request: int
    difference: int
    threshold: int


@dataclass(frozen=True)
class Table:
    """One metric's rows under a benchmark's heading."""

    metric: Metric
    rows: tuple


@dataclass(frozen=True)
class Deviation:
    """One benchmark that crossed a threshold: its tables parsed, and its heading and tables as printed."""

    benchmark: str
    direction: Direction
    tables: tuple
    printed: str


class ShardStatus(Enum):
    """The verdict the workflow read off the tool's stderr and wrote to the status file."""

    WITHIN = "0"
    REGRESSED = "2"
    IMPROVED = "4"
    FAILED = "failed"


@dataclass(frozen=True)
class Compared:
    """A shard whose comparison ran to a verdict. No deviations means everything stayed within thresholds."""

    deviations: tuple


@dataclass(frozen=True)
class Failed:
    """A shard with no comparison that can be trusted, and why."""

    shard: str
    reason: str


class JobResult(Enum):
    """The benchmark job's overall result, as GitHub Actions reports it to a dependent job."""

    SUCCESS = "success"
    FAILURE = "failure"
    CANCELLED = "cancelled"
    SKIPPED = "skipped"


class Delivery(Enum):
    """Whether the comment is news, or only worth refreshing a comment an earlier push left behind."""

    POST = "post"
    REFRESH_ONLY = "refresh-only"


@dataclass(frozen=True)
class Comment:
    body: str
    delivery: Delivery


class ComparisonFormatError(ValueError):
    """A comparison file that does not have the shape `benchmark baseline check` prints."""


def parse_comparison(text):
    """Every deviation in a shard's comparison file, in the order printed, each with its direction.

    A file within thresholds holds no deviations. Raises `ComparisonFormatError` for a file with no
    verdict at all, or with tables after the last verdict, since neither can be filed by direction, and
    for any table that does not parse.
    """
    # Splitting on a pattern with one group alternates [tables, word, tables, word, ..., trailing].
    pieces = VERDICT.split(text)
    groups, trailing = pieces[:-1], pieces[-1]

    if HEADING.search(trailing):
        raise ComparisonFormatError("a deviation table has no verdict after it")
    if not groups and not WITHIN_VERDICT.search(text):
        raise ComparisonFormatError("the comparison holds no verdict")

    return tuple(
        deviation
        for tables, word in zip(groups[0::2], groups[1::2])
        for deviation in deviations(tables, Direction(word))
    )


def deviations(group, direction):
    """The deviations in one verdict's group of tables, each cut from its heading to the next one."""
    headings = list(HEADING.finditer(group))
    ends = [heading.start() for heading in headings[1:]] + [len(group)]

    return [
        deviation(heading["benchmark"], direction, group[heading.start():end].strip())
        for heading, end in zip(headings, ends)
    ]


def deviation(benchmark, direction, printed):
    """One benchmark's deviation from its heading and tables as printed, each table parsed."""
    headers = list(TABLE_HEADER.finditer(printed))
    if not headers:
        raise ComparisonFormatError(f"{benchmark!r} has no table under its heading")
    ends = [header.start() for header in headers[1:]] + [len(printed)]

    tables = tuple(
        table(benchmark, header["metric"], printed[header.end():end], direction)
        for header, end in zip(headers, ends)
    )
    return Deviation(benchmark, direction, tables, printed)


def table(benchmark, title, body, direction):
    """One metric's table from its title and the lines under its header."""
    try:
        metric = Metric(title)
    except ValueError:
        raise ComparisonFormatError(f"{benchmark!r} has a {title!r} table, a metric this script does not judge")

    lines = [line for line in body.splitlines() if line.startswith("|") and not TABLE_RULE.match(line)]
    if not lines:
        raise ComparisonFormatError(f"{benchmark!r} has a {title!r} table with no rows")

    return Table(metric, tuple(row(benchmark, line, direction) for line in lines))


def row(benchmark, line, direction):
    """One percentile's row, which has to move the way its verdict says."""
    match = TABLE_ROW.match(line)
    if not match:
        raise ComparisonFormatError(f"{benchmark!r} has a row that does not parse: {line!r}")
    try:
        percentile = Percentile(match["percentile"])
    except ValueError:
        raise ComparisonFormatError(f"{benchmark!r} has a row for an unknown percentile {match['percentile']!r}")

    parsed = Row(
        percentile,
        int(match["main"]),
        int(match["pull_request"]),
        int(match["difference"]),
        int(match["threshold"]),
    )
    if not moves(parsed, direction):
        raise ComparisonFormatError(
            f"{benchmark!r} is filed as {direction.name.lower()} but its {percentile.value} moved the other way"
        )
    return parsed


def moves(row, direction):
    """Whether a row's signed difference points the way its verdict says. A difference printed as zero,
    an absolute one too small for the table's unit, points either way."""
    match direction:
        case Direction.REGRESSED:
            return row.difference >= 0
        case Direction.IMPROVED:
            return row.difference <= 0


def significance(deviation):
    """A deviation is significant when any of its tables is. Every row in it moved the same way, since
    each was checked against the deviation's verdict as it was parsed."""
    judged = {judgement(table) for table in deviation.tables}
    return Significance.SIGNIFICANT if Significance.SIGNIFICANT in judged else Significance.NOISE


def judgement(table):
    """A counted metric is significant on any percentile; a timed one only when all the central ones crossed."""
    match table.metric.measurement:
        case Measurement.COUNTED:
            return Significance.SIGNIFICANT
        case Measurement.TIMED:
            crossed = {row.percentile for row in table.rows}
            return Significance.SIGNIFICANT if CENTRAL_PERCENTILES <= crossed else Significance.NOISE


def agrees(status, found):
    """Whether the stderr status tells the same story as the directions parsed out of the file."""
    match status:
        case ShardStatus.WITHIN:
            return not found
        case ShardStatus.REGRESSED:
            return Direction.REGRESSED in found
        case ShardStatus.IMPROVED:
            return found == {Direction.IMPROVED}
    return False


def shard_from(shard, status_text, comparison):
    """One shard's outcome from the contents of its status and comparison files."""
    try:
        status = ShardStatus(status_text.strip())
    except ValueError:
        return Failed(shard, f"unrecognized status {status_text.strip()!r}")

    if status is ShardStatus.FAILED:
        return Failed(shard, "the comparison did not run to a verdict")

    try:
        found = parse_comparison(comparison)
    except ComparisonFormatError as error:
        return Failed(shard, str(error))

    directions = {deviation.direction for deviation in found}
    if not agrees(status, directions):
        shown = ", ".join(sorted(d.name.lower() for d in directions)) or "no deviations"
        return Failed(shard, f"the tool reported {status.name.lower()} but the comparison shows {shown}")

    return Compared(found)


def read_shards(directory):
    """Every downloaded shard artifact under `directory`, or none if nothing was downloaded."""
    if not directory.is_dir():
        return []
    return [read_shard(path) for path in sorted(directory.iterdir()) if path.is_dir()]


def read_shard(path):
    status, comparison = path / STATUS_FILE, path / COMPARISON_FILE
    if not status.is_file():
        return Failed(path.name, f"no {STATUS_FILE} in the artifact")

    # A missing comparison reads as an empty one, which fails as having no verdict.
    text = comparison.read_text() if comparison.is_file() else ""
    return shard_from(path.name, status.read_text(), text)


def headline(regressed, improved, incomplete):
    if regressed and improved:
        return f"### ⚠️ {len(regressed)} regressed, {len(improved)} improved vs main"
    if regressed:
        return f"### ⚠️ {len(regressed)} regressed vs main"
    if incomplete:
        return "### ❓ Benchmark comparison incomplete"
    if improved:
        return f"### ✅ {len(improved)} improved, none regressed"
    return "### ✅ No significant benchmark changes"


def names(found):
    return [f"- {flagged.benchmark}" for flagged in found]


def bullets(title, found):
    return [f"**{title}:**", *names(found)]


def printed(found):
    return "\n\n".join(flagged.printed for flagged in found)


def folded(summary, lines):
    return [f"<details><summary>{summary}</summary>", "", *lines, "", "</details>"]


def tally(significant, noise, shard_count):
    """The line under the headline: how many benchmarks count, and how many were set aside."""
    flagged = f"{len(significant)} benchmark(s) flagged across {shard_count} shards"
    if not noise:
        return f"{flagged}."
    more = " more" if significant else ""
    return f"{flagged}; {len(noise)}{more} set aside as noise."


def set_aside(noise):
    return folded(
        f"Set aside as noise ({len(noise)}): time crossed its threshold at only some of p25, p50 and p75",
        [*names(noise), "", printed(noise)],
    )


def paragraphs(*blocks):
    """Blocks of lines joined with a blank line between each, skipping empty blocks."""
    return "\n\n".join("\n".join(block) for block in blocks if block) + "\n"


def no_comparison(job, run_url):
    """The comment when no shard uploaded a comparison: main has no baseline yet, or every shard failed."""
    if job is JobResult.SUCCESS:
        return Comment(
            paragraphs(
                [MARKER, "### Benchmarks ran; no comparison yet"],
                [f"No baseline was available to compare against. [Run details]({run_url})"],
            ),
            Delivery.REFRESH_ONLY,
        )
    return Comment(
        paragraphs(
            [MARKER, "### ❓ Benchmarks did not complete"],
            [f"No shard produced a comparison. [Run details]({run_url})"],
        ),
        Delivery.POST,
    )


def not_run(label):
    """The comment when the pull request lacks the label that turns the comparison on."""
    return Comment(
        paragraphs(
            [MARKER, "### ⏸️ Not run"],
            [f"Add the `{label}` label to compare this pull request's speed with main."],
        ),
        Delivery.POST,
    )


def comment(shards, job, run_url):
    """The rolled-up comment for every shard's outcome and the benchmark job's overall result."""
    if not shards:
        return no_comparison(job, run_url)

    failed = [shard for shard in shards if isinstance(shard, Failed)]
    found = [deviation for shard in shards if isinstance(shard, Compared) for deviation in shard.deviations]
    by_name = sorted(found, key=lambda deviation: deviation.benchmark)
    significant = [d for d in by_name if significance(d) is Significance.SIGNIFICANT]
    noise = [d for d in by_name if significance(d) is Significance.NOISE]
    regressed = [d for d in significant if d.direction is Direction.REGRESSED]
    improved = [d for d in significant if d.direction is Direction.IMPROVED]

    # A shard that failed before uploading leaves no artifact, so the job's own result is a failure
    # signal in its own right, on top of any shard that uploaded a failed status.
    incomplete = bool(failed) or job is not JobResult.SUCCESS

    body = paragraphs(
        [MARKER, headline(regressed, improved, incomplete)],
        [f"{tally(significant, noise, len(shards))} [Run details]({run_url})"],
        [
            "> A shard failed to build or compare, so the picture may be incomplete.",
            *(f"> - {shard.shard}: {shard.reason}" for shard in failed),
        ] if incomplete else [],
        bullets("Regressed", regressed) if regressed else [],
        bullets("Improved", improved) if improved else [],
        # The tool prints only a shard's regressions when it has any, dropping that shard's improvements,
        # and it does so for a regression this script then sets aside as noise too.
        ["> A shard that flags any regression does not report its improvements, so some may be missing."]
        if any(d.direction is Direction.REGRESSED for d in found) else [],
        folded("Regression tables (numbers)", [printed(regressed)]) if regressed else [],
        folded("Improvement tables (numbers)", [printed(improved)]) if improved else [],
        set_aside(noise) if noise else [],
    )

    news = regressed or improved or incomplete
    return Comment(body, Delivery.POST if news else Delivery.REFRESH_ONLY)


RUN_URL = "https://github.com/owner/repo/actions/runs/1"

# The three percentiles the thresholds are set on, in the order the tool prints them.
EVERY_THRESHOLD = ("p25", "p50", "p75")


def fixture_rows(percentiles, main, pull_request, difference, threshold=20):
    return [(percentile, main, pull_request, difference, threshold) for percentile in percentiles]


def fixture_table(title, symbol, rows):
    return (
        f"| {title:<40} |            main |    pull_request | {'Difference ' + symbol:>15} | {'Threshold ' + symbol:>15} |\n"
        "|:-----------------------------------------|----------------:|----------------:|----------------:|----------------:|\n"
        + "".join(
            f"| {percentile:<40} | {main:>15} | {pull_request:>15} | {difference:>15} | {threshold:>15} |\n"
            for percentile, main, pull_request, difference, threshold in rows
        )
        + "\n"
    )


def wall_clock(rows):
    return fixture_table("Time (wall clock) (μs, %)", "%", rows)


def mallocs(rows):
    return fixture_table("Malloc (total) (K, Δ)", "Δ", rows)


def fixture_block(benchmark, *tables):
    return (
        "```\n"
        f"{'=' * 20}\n"
        f"Threshold deviations for SwiftMoneyBenchmarks:{benchmark}\n"
        f"{'=' * 20}\n"
        "```\n"
        + "".join(tables)
    )


def fixture_verdict(word):
    return f"New baseline 'pull_request' is {word} than the 'main' baseline thresholds.\n\n\n"


BETTER_ONLY = (
    fixture_block("MoneyOf unrounded converted", wall_clock(fixture_rows(EVERY_THRESHOLD, 48, 25, -47)))
    + fixture_block("Rate from percent", wall_clock(fixture_rows(EVERY_THRESHOLD, 75, 44, -42)))
    + fixture_verdict("BETTER")
)

WORSE_ONLY = (
    fixture_block("Int from MoneyOf minor units", wall_clock(fixture_rows(EVERY_THRESHOLD, 1678, 2513, 49)))
    + fixture_verdict("WORSE")
)

BOTH_GROUPS = BETTER_ONLY + WORSE_ONLY

WITHIN = "\nNew baseline 'pull_request' is WITHIN the 'main' baseline thresholds.\n"

# Runner noise, as PR #240 saw it in code it did not touch: past the threshold on one percentile or two.
ONE_PERCENTILE = fixture_block("FractionLength construction", wall_clock(fixture_rows(["p25"], 1591, 2234, 40)))
TWO_PERCENTILES = fixture_block(
    "Money scalar multiplication, amount times integer",
    wall_clock([("p25", 2251, 2853, 26, 20), ("p75", 2517, 3074, 22, 20)]),
)
NOISE_ONLY = ONE_PERCENTILE + TWO_PERCENTILES + fixture_verdict("WORSE")

REAL_AND_NOISE = (
    fixture_block("Int from MoneyOf minor units", wall_clock(fixture_rows(EVERY_THRESHOLD, 1678, 2513, 49)))
    + ONE_PERCENTILE
    + TWO_PERCENTILES
    + fixture_verdict("WORSE")
)

# One benchmark slower at its fastest runs and faster at its typical and slow ones.
MIXED_DIRECTIONS = (
    fixture_block("Harness floor, an integer", wall_clock(fixture_rows(["p25"], 1556, 1900, 22)))
    + fixture_verdict("WORSE")
    + fixture_block("Harness floor, an integer", wall_clock(fixture_rows(["p50", "p75"], 1600, 1200, -25)))
    + fixture_verdict("BETTER")
)

ONE_MALLOC = fixture_block("Money bytes decode", mallocs(fixture_rows(["p50"], 16, 22, 6, 4))) + fixture_verdict("WORSE")

ORPHAN =fixture_block("Orphan", wall_clock(fixture_rows(["p25"], 1, 2, 100)))


def selftest():
    improved = parse_comparison(BETTER_ONLY)
    assert [(d.benchmark, d.direction) for d in improved] == [
        ("MoneyOf unrounded converted", Direction.IMPROVED),
        ("Rate from percent", Direction.IMPROVED),
    ], improved

    regressed = parse_comparison(WORSE_ONLY)
    assert [(d.benchmark, d.direction) for d in regressed] == [
        ("Int from MoneyOf minor units", Direction.REGRESSED),
    ], regressed

    both = parse_comparison(BOTH_GROUPS)
    assert [(d.benchmark, d.direction) for d in both] == [
        ("MoneyOf unrounded converted", Direction.IMPROVED),
        ("Rate from percent", Direction.IMPROVED),
        ("Int from MoneyOf minor units", Direction.REGRESSED),
    ], both
    # Each deviation keeps its own heading and table, and none of the verdict lines around it.
    assert both[2].printed.startswith("```\n"), both[2].printed
    assert "Int from MoneyOf minor units" in both[2].printed and "| p25" in both[2].printed
    assert all("New baseline" not in d.printed for d in both)
    assert "Rate from percent" not in both[0].printed

    # Each table is parsed once into its metric and its rows, the numbers as the tool printed them.
    assert both[2].tables == (
        Table(Metric.WALL_CLOCK, (
            Row(Percentile.P25, 1678, 2513, 49, 20),
            Row(Percentile.P50, 1678, 2513, 49, 20),
            Row(Percentile.P75, 1678, 2513, 49, 20),
        )),
    ), both[2].tables

    # One benchmark can print a table per metric; the malloc table's title itself holds parentheses.
    split = parse_comparison(
        fixture_block(
            "MoneyOf split by weights",
            wall_clock(fixture_rows(EVERY_THRESHOLD, 144, 187, 30)),
            mallocs(fixture_rows(EVERY_THRESHOLD, 3000, 3900, 900, 0)),
        )
        + fixture_verdict("WORSE")
    )
    assert [table.metric for table in split[0].tables] == [Metric.WALL_CLOCK, Metric.MALLOC_TOTAL], split
    assert split[0].tables[1].rows[0] == Row(Percentile.P25, 3000, 3900, 900, 0), split

    instructions = parse_comparison(
        fixture_block("Counted", fixture_table("Instructions (M, %)", "%", fixture_rows(["p50"], 10, 12, 20, 5)))
        + fixture_verdict("WORSE")
    )
    assert instructions[0].tables[0].metric is Metric.INSTRUCTIONS, instructions

    # A warning the tool prints above the tables belongs to no benchmark.
    warned = parse_comparison(
        "One or more benchmarks, including `SwiftMoneyBenchmarks:New` was not found in one of the baselines.\n\n"
        + WORSE_ONLY
    )
    assert warned == parse_comparison(WORSE_ONLY), warned

    assert parse_comparison(WITHIN) == ()

    for broken, why in [
        ("", "an empty file has no verdict"),
        (ORPHAN, "a table with no verdict after it"),
        (BETTER_ONLY + ORPHAN, "a table after the last verdict"),
        (
            fixture_block("Unknown", fixture_table("Syscalls (total) (#, %)", "%", fixture_rows(["p25"], 1, 2, 100)))
            + fixture_verdict("WORSE"),
            "a metric this script does not know how to judge",
        ),
        (
            fixture_block("Odd", wall_clock(fixture_rows(["p42"], 1, 2, 100))) + fixture_verdict("WORSE"),
            "a percentile the tool never prints",
        ),
        (fixture_block("Empty") + fixture_verdict("WORSE"), "a heading with no table under it"),
        (
            fixture_block("Headless", wall_clock([])) + fixture_verdict("WORSE"),
            "a table with no rows",
        ),
        (
            fixture_block("Garbled", wall_clock(fixture_rows(["p25"], 1, 2, 100)) + "| p50 | 1 | two | 100 | 20 |\n")
            + fixture_verdict("WORSE"),
            "a row that does not parse",
        ),
        (
            fixture_block("Backwards", wall_clock(fixture_rows(EVERY_THRESHOLD, 48, 25, -47)))
            + fixture_verdict("WORSE"),
            "a row moving against its verdict",
        ),
    ]:
        try:
            parse_comparison(broken)
        except ComparisonFormatError:
            pass
        else:
            raise AssertionError(f"expected a format error for {why}")

    # Wall clock counts only when p25, p50 and p75 all cross in the same direction. Allocations and
    # instructions are counted exactly, so they count on any percentile.
    def judged(text):
        return [(d.benchmark, significance(d)) for d in parse_comparison(text)]

    assert judged(WORSE_ONLY) == [("Int from MoneyOf minor units", Significance.SIGNIFICANT)]
    assert judged(BETTER_ONLY) == [
        ("MoneyOf unrounded converted", Significance.SIGNIFICANT),
        ("Rate from percent", Significance.SIGNIFICANT),
    ]
    assert judged(TWO_PERCENTILES + fixture_verdict("WORSE")) == [
        ("Money scalar multiplication, amount times integer", Significance.NOISE),
    ]
    assert judged(ONE_PERCENTILE + fixture_verdict("WORSE")) == [
        ("FractionLength construction", Significance.NOISE),
    ]
    assert judged(MIXED_DIRECTIONS) == [
        ("Harness floor, an integer", Significance.NOISE),
        ("Harness floor, an integer", Significance.NOISE),
    ]
    assert judged(ONE_MALLOC) == [("Money bytes decode", Significance.SIGNIFICANT)]
    assert judged(
        fixture_block(
            "Money split by weights",
            wall_clock(fixture_rows(["p25"], 144, 191, 32)),
            mallocs(fixture_rows(["p75"], 3000, 3900, 900, 0)),
        )
        + fixture_verdict("WORSE")
    ) == [("Money split by weights", Significance.SIGNIFICANT)], "an exact metric outweighs a noisy one"
    assert [significance(d) for d in instructions] == [Significance.SIGNIFICANT]

    # The stderr status and the parsed file must tell the same story, or the shard is not trusted.
    assert shard_from("shard0", "4\n", BETTER_ONLY) == Compared(parse_comparison(BETTER_ONLY))
    assert shard_from("shard0", "2\n", BOTH_GROUPS) == Compared(parse_comparison(BOTH_GROUPS))
    assert shard_from("shard0", "0\n", WITHIN) == Compared(())
    for status, text in [("2", BETTER_ONLY), ("4", BOTH_GROUPS), ("0", WORSE_ONLY), ("4", WITHIN)]:
        assert isinstance(shard_from("shard0", status, text), Failed), (status, text)
    assert isinstance(shard_from("shard0", "0", ""), Failed), "status 0 with no verdict"
    assert isinstance(shard_from("shard0", "failed\n", BETTER_ONLY), Failed)
    assert isinstance(shard_from("shard0", "banana", BETTER_ONLY), Failed)
    # The status reports what the tool flagged, noise included, so noise still agrees with it.
    assert shard_from("shard0", "2", NOISE_ONLY) == Compared(parse_comparison(NOISE_ONLY))

    mixed = [
        shard_from("shard0", "4", BETTER_ONLY),
        shard_from("shard1", "2", WORSE_ONLY),
        shard_from("shard2", "0", WITHIN),
    ]
    mixed_comment = comment(mixed, JobResult.SUCCESS, RUN_URL)
    lines = mixed_comment.body.splitlines()
    assert lines[0] == "<!-- benchmark-delta -->", lines[0]
    assert lines[1] == "### ⚠️ 1 regressed, 2 improved vs main", lines[1]
    assert mixed_comment.delivery is Delivery.POST
    assert RUN_URL in mixed_comment.body
    regressed_at, improved_at = lines.index("**Regressed:**"), lines.index("**Improved:**")
    assert regressed_at < improved_at
    assert lines[regressed_at + 1:regressed_at + 2] == ["- Int from MoneyOf minor units"]
    assert lines[improved_at + 1:improved_at + 3] == ["- MoneyOf unrounded converted", "- Rate from percent"]
    # Regressions need attention, so their tables fold away first.
    body = mixed_comment.body
    assert body.index("Int from MoneyOf minor units\n=") < body.index("Rate from percent\n=")
    assert body.count("<details>") == 2
    assert "incomplete" not in body
    assert "noise" not in body

    # Noise stays out of the headline and the lists, and folds away below the real changes.
    with_noise = comment(
        [shard_from("shard0", "4", BETTER_ONLY), shard_from("shard1", "2", REAL_AND_NOISE)],
        JobResult.SUCCESS,
        RUN_URL,
    )
    lines = with_noise.body.splitlines()
    assert lines[1] == "### ⚠️ 1 regressed, 2 improved vs main", lines[1]
    assert f"3 benchmark(s) flagged across 2 shards; 2 more set aside as noise. [Run details]({RUN_URL})" in lines
    regressed_at = lines.index("**Regressed:**")
    assert lines[regressed_at + 1:regressed_at + 3] == ["- Int from MoneyOf minor units", ""], lines
    assert with_noise.delivery is Delivery.POST
    body = with_noise.body
    noise_at = body.index("<details><summary>Set aside as noise (2)")
    assert body.index("Improvement tables") < noise_at
    for name in ["FractionLength construction", "Money scalar multiplication, amount times integer"]:
        assert body.index(f"- {name}") > noise_at and body.index(f"{name}\n=") > noise_at, name
    assert body.count("<details>") == 3

    # A run whose every flag was noise is no news.
    all_noise = comment(
        [shard_from("shard0", "2", NOISE_ONLY), shard_from("shard1", "0", WITHIN)],
        JobResult.SUCCESS,
        RUN_URL,
    )
    lines = all_noise.body.splitlines()
    assert lines[1] == "### ✅ No significant benchmark changes", lines[1]
    assert f"0 benchmark(s) flagged across 2 shards; 2 set aside as noise. [Run details]({RUN_URL})" in lines, lines
    assert "**Regressed:**" not in all_noise.body and "**Improved:**" not in all_noise.body
    assert "- FractionLength construction" in all_noise.body
    assert all_noise.delivery is Delivery.REFRESH_ONLY
    # The tool drops a shard's improvements for any regression, noise or not.
    assert "does not report its improvements" in all_noise.body

    noise_and_failed = comment(
        [shard_from("shard0", "2", NOISE_ONLY), shard_from("shard3", "failed", "")],
        JobResult.FAILURE,
        RUN_URL,
    )
    assert noise_and_failed.body.splitlines()[1] == "### ❓ Benchmark comparison incomplete"
    assert noise_and_failed.delivery is Delivery.POST

    regressed_only = comment([shard_from("shard0", "2", WORSE_ONLY)], JobResult.SUCCESS, RUN_URL)
    assert regressed_only.body.splitlines()[1] == "### ⚠️ 1 regressed vs main"
    assert "**Improved:**" not in regressed_only.body

    improved_only = comment([shard_from("shard0", "4", BETTER_ONLY)], JobResult.SUCCESS, RUN_URL)
    assert improved_only.body.splitlines()[1] == "### ✅ 2 improved, none regressed"
    assert "**Regressed:**" not in improved_only.body
    assert improved_only.delivery is Delivery.POST

    quiet = comment([shard_from("shard0", "0", WITHIN)], JobResult.SUCCESS, RUN_URL)
    assert quiet.body.splitlines()[1] == "### ✅ No significant benchmark changes"
    assert quiet.delivery is Delivery.REFRESH_ONLY
    assert "<details>" not in quiet.body

    # A failed shard surfaces, by name, whatever else the other shards found.
    with_failure = comment(
        [shard_from("shard0", "4", BETTER_ONLY), shard_from("shard3", "failed", "")],
        JobResult.FAILURE,
        RUN_URL,
    )
    assert with_failure.body.splitlines()[1] == "### ❓ Benchmark comparison incomplete"
    assert "shard3" in with_failure.body
    assert "- Rate from percent" in with_failure.body
    assert with_failure.delivery is Delivery.POST

    regressed_and_failed = comment(
        [shard_from("shard1", "2", WORSE_ONLY), shard_from("shard3", "failed", "")],
        JobResult.FAILURE,
        RUN_URL,
    )
    assert regressed_and_failed.body.splitlines()[1] == "### ⚠️ 1 regressed vs main"
    assert "incomplete" in regressed_and_failed.body

    # A shard that failed before uploading leaves no artifact; only the job result says so.
    missing_artifact = comment([shard_from("shard0", "0", WITHIN)], JobResult.FAILURE, RUN_URL)
    assert missing_artifact.body.splitlines()[1] == "### ❓ Benchmark comparison incomplete"
    assert missing_artifact.delivery is Delivery.POST

    no_baseline = comment([], JobResult.SUCCESS, RUN_URL)
    assert no_baseline.body.splitlines()[1] == "### Benchmarks ran; no comparison yet"
    assert no_baseline.delivery is Delivery.REFRESH_ONLY

    nothing_ran = comment([], JobResult.FAILURE, RUN_URL)
    assert nothing_ran.body.splitlines()[1] == "### ❓ Benchmarks did not complete"
    assert nothing_ran.delivery is Delivery.POST

    # Posted, not only refreshed, so it also replaces the result of a push that had the label.
    unlabelled = not_run("run-benchmarks")
    assert unlabelled.body.splitlines()[:2] == [MARKER, "### ⏸️ Not run"], unlabelled.body
    assert "`run-benchmarks`" in unlabelled.body
    assert unlabelled.delivery is Delivery.POST

    with tempfile.TemporaryDirectory() as root:
        artifacts = Path(root)
        for name, status, text in [
            ("benchmark-delta-shard0", "4\n", BETTER_ONLY),
            ("benchmark-delta-shard1", "0\n", WITHIN),
        ]:
            (artifacts / name).mkdir()
            (artifacts / name / "shard_status.txt").write_text(status)
            (artifacts / name / "shard_comparison.md").write_text(text)
        (artifacts / "benchmark-delta-shard2").mkdir()
        (artifacts / "benchmark-delta-shard2" / "shard_status.txt").write_text("2\n")

        shards = read_shards(artifacts)
        assert shards[:2] == [Compared(parse_comparison(BETTER_ONLY)), Compared(())], shards
        assert isinstance(shards[2], Failed) and shards[2].shard == "benchmark-delta-shard2", shards[2]
        assert read_shards(artifacts / "absent") == []

    print("selftest OK: comparisons parsed by direction and every comment shape rendered")


def main(argv):
    if "--selftest" in argv:
        selftest()
        return 0

    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("shards", type=Path, nargs="?",
                        help="the directory the shard artifacts were downloaded into")
    parser.add_argument("--not-run", metavar="LABEL",
                        help="write the comment for a pull request without LABEL, instead of reading shards")
    parser.add_argument("--job-result", choices=[result.value for result in JobResult],
                        help="the benchmark job's result, from needs.benchmark.result")
    parser.add_argument("--run-url", help="the workflow run the comment links to")
    parser.add_argument("--github-env", type=Path,
                        help="a file to append DELIVERY=post|refresh-only to, such as $GITHUB_ENV")
    args = parser.parse_args(argv[1:])

    comparison = (args.shards, args.job_result, args.run_url)
    if args.not_run and not any(comparison):
        result = not_run(args.not_run)
    elif all(comparison) and not args.not_run:
        result = comment(read_shards(args.shards), JobResult(args.job_result), args.run_url)
    else:
        parser.error("give either --not-run LABEL, or shards with --job-result and --run-url")

    sys.stdout.write(result.body)
    print(f"delivery: {result.delivery.value}", file=sys.stderr)
    if args.github_env:
        with open(args.github_env, "a") as environment:
            environment.write(f"DELIVERY={result.delivery.value}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

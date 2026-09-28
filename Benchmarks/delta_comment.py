#!/usr/bin/env python3
"""Build the benchmark delta PR comment from every shard's comparison against main.

Each shard of the delta workflow uploads an artifact holding two files: `shard_comparison.md`, the
markdown `benchmark baseline check` printed, and `shard_status.txt`, the verdict the workflow read off
the tool's stderr. This reads every downloaded artifact and prints one comment body that says which
benchmarks regressed and which improved:

    python3 Benchmarks/delta_comment.py shards --job-result success --run-url <url> > comment_body.md

Direction comes from the comparison file, not the status. The status is one word per shard, and a
regression outranks an improvement in it, so a shard that did both reads as a plain regression. In the
file, every group of deviation tables is followed by a verdict line saying whether that group is
BETTER or WORSE than main, which is what each benchmark is filed under here. The status is still
checked against the file, and a shard where the two disagree is reported as failed rather than trusted.

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


class Direction(Enum):
    """Which way a benchmark moved past its threshold, keyed on the word in the tool's verdict line."""

    REGRESSED = "WORSE"
    IMPROVED = "BETTER"


@dataclass(frozen=True)
class Deviation:
    """One benchmark that crossed a threshold, with its heading and tables as the tool printed them."""

    benchmark: str
    direction: Direction
    tables: str


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
    verdict at all, or with tables after the last verdict, since neither can be filed by direction.
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
        Deviation(heading["benchmark"], direction, group[heading.start():end].strip())
        for heading, end in zip(headings, ends)
    ]


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


def bullets(title, found):
    return [f"**{title}:**", *(f"- {deviation.benchmark}" for deviation in found)]


def folded(summary, found):
    return [
        f"<details><summary>{summary}</summary>",
        "",
        "\n\n".join(deviation.tables for deviation in found),
        "",
        "</details>",
    ]


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


def comment(shards, job, run_url):
    """The rolled-up comment for every shard's outcome and the benchmark job's overall result."""
    if not shards:
        return no_comparison(job, run_url)

    failed = [shard for shard in shards if isinstance(shard, Failed)]
    found = [deviation for shard in shards if isinstance(shard, Compared) for deviation in shard.deviations]
    by_name = sorted(found, key=lambda deviation: deviation.benchmark)
    regressed = [d for d in by_name if d.direction is Direction.REGRESSED]
    improved = [d for d in by_name if d.direction is Direction.IMPROVED]

    # A shard that failed before uploading leaves no artifact, so the job's own result is a failure
    # signal in its own right, on top of any shard that uploaded a failed status.
    incomplete = bool(failed) or job is not JobResult.SUCCESS

    body = paragraphs(
        [MARKER, headline(regressed, improved, incomplete)],
        [f"{len(found)} benchmark(s) flagged across {len(shards)} shards. [Run details]({run_url})"],
        [
            "> A shard failed to build or compare, so the picture may be incomplete.",
            *(f"> - {shard.shard}: {shard.reason}" for shard in failed),
        ] if incomplete else [],
        bullets("Regressed", regressed) if regressed else [],
        bullets("Improved", improved) if improved else [],
        # The tool prints only a shard's regressions when it has any, dropping that shard's improvements.
        ["> A shard that regressed does not report its improvements, so the improved list may be short."]
        if regressed else [],
        folded("Regression tables (numbers)", regressed) if regressed else [],
        folded("Improvement tables (numbers)", improved) if improved else [],
    )

    news = regressed or improved or incomplete
    return Comment(body, Delivery.POST if news else Delivery.REFRESH_ONLY)


RUN_URL = "https://github.com/owner/repo/actions/runs/1"


def fixture_block(benchmark, main, pull_request, difference):
    return (
        "```\n"
        f"{'=' * 20}\n"
        f"Threshold deviations for SwiftMoneyBenchmarks:{benchmark}\n"
        f"{'=' * 20}\n"
        "```\n"
        "| Time (wall clock) (μs, %)                |            main |    pull_request |    Difference % |     Threshold % |\n"
        "|:-----------------------------------------|----------------:|----------------:|----------------:|----------------:|\n"
        f"| p25                                      | {main:>15} | {pull_request:>15} | {difference:>15} |              20 |\n"
        "\n"
    )


def fixture_verdict(word):
    return f"New baseline 'pull_request' is {word} than the 'main' baseline thresholds.\n\n\n"


BETTER_ONLY = (
    fixture_block("MoneyOf unrounded converted", 48, 25, -47)
    + fixture_block("Rate from percent", 75, 44, -42)
    + fixture_verdict("BETTER")
)

WORSE_ONLY = fixture_block("FractionLength construction", 1591, 2234, 40) + fixture_verdict("WORSE")

BOTH_GROUPS = BETTER_ONLY + WORSE_ONLY

WITHIN = "\nNew baseline 'pull_request' is WITHIN the 'main' baseline thresholds.\n"


def selftest():
    improved = parse_comparison(BETTER_ONLY)
    assert [(d.benchmark, d.direction) for d in improved] == [
        ("MoneyOf unrounded converted", Direction.IMPROVED),
        ("Rate from percent", Direction.IMPROVED),
    ], improved

    regressed = parse_comparison(WORSE_ONLY)
    assert [(d.benchmark, d.direction) for d in regressed] == [
        ("FractionLength construction", Direction.REGRESSED),
    ], regressed

    both = parse_comparison(BOTH_GROUPS)
    assert [(d.benchmark, d.direction) for d in both] == [
        ("MoneyOf unrounded converted", Direction.IMPROVED),
        ("Rate from percent", Direction.IMPROVED),
        ("FractionLength construction", Direction.REGRESSED),
    ], both
    # Each deviation keeps its own heading and table, and none of the verdict lines around it.
    assert both[2].tables.startswith("```\n"), both[2].tables
    assert "FractionLength construction" in both[2].tables and "| p25" in both[2].tables
    assert all("New baseline" not in d.tables for d in both)
    assert "Rate from percent" not in both[0].tables

    assert parse_comparison(WITHIN) == ()

    for broken, why in [
        ("", "an empty file has no verdict"),
        (fixture_block("Orphan", 1, 2, 100), "a table with no verdict after it"),
        (BETTER_ONLY + fixture_block("Orphan", 1, 2, 100), "a table after the last verdict"),
    ]:
        try:
            parse_comparison(broken)
        except ComparisonFormatError:
            pass
        else:
            raise AssertionError(f"expected a format error for {why}")

    # The stderr status and the parsed file must tell the same story, or the shard is not trusted.
    assert shard_from("shard0", "4\n", BETTER_ONLY) == Compared(parse_comparison(BETTER_ONLY))
    assert shard_from("shard0", "2\n", BOTH_GROUPS) == Compared(parse_comparison(BOTH_GROUPS))
    assert shard_from("shard0", "0\n", WITHIN) == Compared(())
    for status, text in [("2", BETTER_ONLY), ("4", BOTH_GROUPS), ("0", WORSE_ONLY), ("4", WITHIN)]:
        assert isinstance(shard_from("shard0", status, text), Failed), (status, text)
    assert isinstance(shard_from("shard0", "0", ""), Failed), "status 0 with no verdict"
    assert isinstance(shard_from("shard0", "failed\n", BETTER_ONLY), Failed)
    assert isinstance(shard_from("shard0", "banana", BETTER_ONLY), Failed)

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
    assert lines[regressed_at + 1:regressed_at + 2] == ["- FractionLength construction"]
    assert lines[improved_at + 1:improved_at + 3] == ["- MoneyOf unrounded converted", "- Rate from percent"]
    # Regressions need attention, so their tables fold away first.
    body = mixed_comment.body
    assert body.index("FractionLength construction\n=") < body.index("Rate from percent\n=")
    assert body.count("<details>") == 2
    assert "incomplete" not in body

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
    parser.add_argument("shards", type=Path, help="the directory the shard artifacts were downloaded into")
    parser.add_argument("--job-result", required=True, choices=[result.value for result in JobResult],
                        help="the benchmark job's result, from needs.benchmark.result")
    parser.add_argument("--run-url", required=True, help="the workflow run the comment links to")
    parser.add_argument("--github-env", type=Path,
                        help="a file to append DELIVERY=post|refresh-only to, such as $GITHUB_ENV")
    args = parser.parse_args(argv[1:])

    result = comment(read_shards(args.shards), JobResult(args.job_result), args.run_url)

    sys.stdout.write(result.body)
    print(f"delivery: {result.delivery.value}", file=sys.stderr)
    if args.github_env:
        with open(args.github_env, "a") as environment:
            environment.write(f"DELIVERY={result.delivery.value}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

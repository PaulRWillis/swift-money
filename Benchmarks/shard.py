#!/usr/bin/env python3
"""Partition the benchmark set into shards for parallel CI runs.

Reads benchmark names (the output of `swift package benchmark list`) on stdin and prints the
`--filter` patterns for one shard, one per line, so a CI leg runs only its slice:

    swift package --package-path Benchmarks benchmark list \
        | python3 Benchmarks/shard.py <shard-index> <shard-count>

Names are read fresh from `benchmark list` every run, so a newly added benchmark is picked up
automatically: it appears in the list, lands in a shard, and gets compared, with no edit here or in
the workflow. Assignment is round-robin over the sorted names, which keeps every shard within one
benchmark of the same size and spreads a cluster of new benchmarks across all shards rather than onto
one. The partition is verified to cover every input name exactly once, so a bug fails the run loudly
instead of silently dropping a benchmark.

Each printed pattern is the benchmark name escaped as a regular-expression literal. The plugin matches
a filter against the whole name (`wholeMatch`), so an escaped literal selects exactly that benchmark;
`--filter` may be repeated and the matches are OR-ed together.

    python3 Benchmarks/shard.py --selftest    # verify the partition and escaping, no stdin needed
"""

import re
import sys


def read_names(lines):
    """The benchmark names from `benchmark list` output, dropping its header and blank lines.

    `benchmark list` prints a `Target '…' available benchmarks:` header then one name per line. When
    no header is present every non-blank line is taken as a name, so a plain list can be piped in too.
    """
    stripped = [line.strip() for line in lines]
    header = next((i for i, line in enumerate(stripped) if line.endswith("available benchmarks:")), None)
    body = stripped[header + 1:] if header is not None else stripped
    return [line for line in body if line]


def shards(names, count):
    """The names grouped into `count` shards by round-robin over their sorted order.

    Fails loudly on a duplicate name (benchmark names must be unique — a collision would also corrupt
    the stored baselines) or if the shards do not cover every name exactly once.
    """
    if count < 1:
        raise ValueError(f"shard count must be at least 1, got {count}")

    ordered = sorted(names)
    duplicates = {name for name in ordered if ordered.count(name) > 1}
    if duplicates:
        raise ValueError(f"duplicate benchmark name(s): {', '.join(sorted(duplicates))}")

    groups = [ordered[i::count] for i in range(count)]

    covered = [name for group in groups for name in group]
    if sorted(covered) != ordered or len(covered) != len(ordered):
        raise ValueError("partition did not cover every benchmark exactly once")

    return groups


def pattern(name):
    """`name` as a regex literal the plugin's whole-name filter matches only against that name."""
    return re.escape(name)


def selftest():
    names = [
        "Int addition",
        "MoneyOf addition",
        "MoneyOf format, .standard, en_GB [engine]",
        "Decimal format, .standard, en_GB [ICU]",
        "MoneyOf scaled and rounded",
        "Weights construction",
    ]
    count = 3
    groups = shards(names, count)

    flat = [name for group in groups for name in group]
    assert sorted(flat) == sorted(names), "shards must cover every name"
    assert len(flat) == len(set(flat)), "shards must be disjoint"
    assert max(len(g) for g in groups) - min(len(g) for g in groups) <= 1, "shards must be balanced"

    for name in names:
        matches = [other for other in names if re.fullmatch(pattern(name), other)]
        assert matches == [name], f"pattern for {name!r} matched {matches!r}"

    print(f"selftest OK: {len(names)} names into {count} balanced, disjoint, complete shards")


def main(argv):
    if "--selftest" in argv:
        selftest()
        return 0

    if len(argv) != 3:
        sys.stderr.write("usage: benchmark list | shard.py <shard-index> <shard-count>\n")
        return 2

    index, count = int(argv[1]), int(argv[2])
    if not 0 <= index < count:
        sys.stderr.write(f"shard index {index} out of range for count {count}\n")
        return 2

    names = read_names(sys.stdin.readlines())
    for name in shards(names, count)[index]:
        print(pattern(name))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

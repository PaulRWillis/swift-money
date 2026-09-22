# Benchmarks

SwiftMoney stores monetary values as `Int64` minor units, while `Foundation.Decimal` uses a 128-bit
decimal floating-point representation. This page compares the two approaches across common operations
to help you understand the performance trade-offs.

All benchmarks use [package-benchmark](https://github.com/ordo-one/package-benchmark) and run on
GitHub Actions (Ubuntu, x86_64). Numbers are median (p50) values. Heap allocations are measured
via `malloc` instrumentation.

## Run locally

```bash
swift package --package-path Benchmarks benchmark run
```

## Summary

<!-- BENCHMARK-SUMMARY-START -->
### SwiftMoney against the alternatives

| Operation | Ours | Int | Double | Decimal |
|:----------|----------:|----------:|----------:|----------:|
| Addition | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 6 allocs, 334 ns |
| Subtraction | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 7 allocs, 346 ns |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 5 allocs, 271 ns |
| Scale and round | 0 instr, 28 ns | 0 instr, 1 ns | 0 instr, 4 ns | 0 instr, 83 allocs, 5085 ns |
| Comparison | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 4 allocs, 161 ns |
| Split into 3 | 0 instr, 9 ns | 0 instr, 3 ns | 0 instr, 4 ns | 0 instr, 37 allocs, 2457 ns |
| Chained scaling | 0 instr, 169 ns | 0 instr, 2 ns | 0 instr, 6 ns | 0 instr, 41 allocs, 2651 ns |

### Formatting, option by option, against Foundation

| Operation | Ours | Decimal | Speedup |
|:----------|----------:|----------:|----------:|
| Default | 0 instr, 943 ns | 0 instr, 10 allocs, 2370 ns | **∞** |
| Runtime currency | 0 instr, 941 ns | 0 instr, 10 allocs, 2370 ns | **∞** |
| ISO code | 0 instr, 965 ns | 0 instr, 10 allocs, 2535 ns | **∞** |
| Narrow symbol | 0 instr, 967 ns | 0 instr, 10 allocs, 2411 ns | **∞** |
| Full name | 0 instr, 1 alloc, 1440 ns | 0 instr, 11 allocs, 2603 ns | **∞** |
| Sign, never | 0 instr, 958 ns | 0 instr, 11 allocs, 2550 ns | **∞** |
| Sign, always | 0 instr, 967 ns | 0 instr, 11 allocs, 2605 ns | **∞** |
| Sign, accounting | 0 instr, 981 ns | 0 instr, 12 allocs, 2642 ns | **∞** |
| Grouping, never | 0 instr, 967 ns | 0 instr, 21 allocs, 3524 ns | **∞** |
| Decimal separator, always | 0 instr, 946 ns | 0 instr, 11 allocs, 2522 ns | **∞** |
| Precision, 2dp | 0 instr, 990 ns | 0 instr, 10 allocs, 2384 ns | **∞** |
| Precision, 1dp | 0 instr, 995 ns | 0 instr, 10 allocs, 2382 ns | **∞** |
| Precision and accounting | 0 instr, 1027 ns | 0 instr, 12 allocs, 2631 ns | **∞** |
| Every option | 0 instr, 1054 ns | 0 instr, 10 allocs, 1947 ns | **∞** |
| Rounding increment | 0 instr, 18 allocs, 3345 ns | n/a | n/a |
| Attributed | 0 instr, 35 allocs, 36000 ns | 0 instr, 42 allocs, 25000 ns | **∞** |
| Parse | 0 instr, 18 allocs, 4083 ns | 0 instr, 7 allocs, 2564 ns | **∞** |

### What the measurement itself costs

| Operation | Ours |
|:----------|----------:|
| Handing an integer to the harness | 0 instr, 2 ns |
| Handing a struct to the harness | 0 instr, 3 ns |

### SwiftMoney's own operations

| Operation | Ours |
|:----------|----------:|
| Addition, throwing | 0 instr, 3 ns |
| Scale, leaving it unrounded | 0 instr, 95 ns |
| Unrounded addition | 0 instr, 4 ns |
| Chained scaling, rounding each step | 0 instr, 87 ns |
| Split into 3, runtime currency | 0 instr, 10 ns |
| Split, iterating the parts | 0 instr, 253 ns |
| Total of 10 | 0 instr, 7 ns |
| Currency code validation | 0 instr, 24 ns |
| Proportion | 0 instr, 23 ns |
| Proportion of large amounts | 0 instr, 33 ns |
| Addition, separately built currencies | 0 instr, 4 ns |
<!-- BENCHMARK-SUMMARY-END -->

## Analysis

### Zero-allocation arithmetic

SwiftMoney's core arithmetic (`+`, `-`, `*`, `<`) operates directly on `Int64` with **zero heap
allocations**. `Foundation.Decimal` allocates on every arithmetic operation due to its internal
bridging from the Objective-C `NSDecimalNumber` representation. In tight loops — batch processing,
trading engines, ledger reconciliation — this difference compounds significantly.

### Codable

The `.minorUnits` encoding strategy writes a bare integer (e.g. `12550`), avoiding `Decimal`'s
string-based encoding overhead. Encode is faster; decode is comparable because both go through
`JSONDecoder` machinery. For highest throughput, use `.minorUnits` over `.object` or `.string`
strategies.

### Formatting

Both `Money<C>.formatted()` and `Decimal.FormatStyle.Currency` ultimately delegate to ICU's
number formatter. SwiftMoney applies a scale factor to convert minor units to major units before
formatting, which adds a small overhead. Formatting is a cold-path operation (UI rendering, report
generation), so the difference is negligible in practice.

### SwiftMoney-only operations

These operations have no `Decimal` equivalent — they are unique to SwiftMoney's domain model.
Exact timings are in the summary table above.

- **Distribution** (`distributed(into:)`) — splits a monetary amount into N shares with a
  remainder guarantee. Zero allocations.
- **Exchange rate conversion** (`ExchangeRate.convert(_:)`) — converts between currency types
  using exact rational arithmetic. Zero allocations.
- **MoneyBag accumulation** — inserts multiple currency entries into a multi-currency bag.
  Single allocation for dictionary growth.
- **NaN check** (`isNaN`) — single `Int64` comparison. Sub-nanosecond, zero allocations.

## Detailed results

The raw percentile tables below are auto-generated by CI on each push to `main`.

<!-- BENCHMARK-START -->

## Baseline 'Current_run'

```
Host 'runnervmlun5p' with 4 'x86_64' processors with 15 GB memory, running:
#22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026
```
## SwiftMoneyBenchmarks

### Control JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         2 |
| Time (wall clock) (ns) * |       699 |       699 |       699 |       699 |       699 |       699 |       699 |         2 |

### Control JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         2 |
| Time (wall clock) (ns) * |       508 |       508 |       508 |       510 |       510 |       510 |       510 |         2 |

### Currency construction, custom

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        11 |       105 |

### CurrencyCode description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        59 |
| Time (wall clock) (ns) * |        17 |        17 |        17 |        17 |        17 |        17 |        17 |        59 |

### CurrencyCode validation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        24 |        24 |        24 |        25 |        25 |        43 |

### CurrencyCode validation, eight characters

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        23 |
| Time (wall clock) (ns) * |        45 |        45 |        45 |        45 |        45 |        46 |        46 |        23 |

### Decimal JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         8 |         8 |         8 |         8 |         8 |         8 |         8 |         2 |
| Time (wall clock) (ns) * |       952 |       953 |       953 |       955 |       955 |       955 |       955 |         2 |

### Decimal JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       838 |       838 |       838 |       839 |       839 |       839 |       839 |         2 |

### Decimal addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         3 |
| Time (wall clock) (ns) * |       334 |       334 |       334 |       334 |       334 |       334 |       334 |         3 |

### Decimal attributed, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        42 |        42 |        42 |        42 |        42 |        42 |        42 |         1 |
| Time (wall clock) (μs) * |        25 |        25 |        25 |        25 |        25 |        25 |        25 |         1 |

### Decimal chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        41 |        41 |        41 |        41 |        41 |        41 |        41 |         1 |
| Time (wall clock) (ns) * |      2651 |      2651 |      2651 |      2651 |      2651 |      2651 |      2651 |         1 |

### Decimal comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         7 |
| Time (wall clock) (ns) * |       160 |       160 |       161 |       161 |       161 |       161 |       161 |         7 |

### Decimal description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         3 |
| Time (wall clock) (ns) * |       453 |       453 |       453 |       454 |       454 |       454 |       454 |         3 |

### Decimal divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        37 |        37 |        37 |        37 |        37 |        37 |        37 |         1 |
| Time (wall clock) (ns) * |      2457 |      2457 |      2457 |      2457 |      2457 |      2457 |      2457 |         1 |

### Decimal format, ISO code, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      2535 |      2535 |      2535 |      2535 |      2535 |      2535 |      2535 |         1 |

### Decimal format, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      2370 |      2370 |      2370 |      2370 |      2370 |      2370 |      2370 |         1 |

### Decimal format, every option, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      1947 |      1947 |      1947 |      1947 |      1947 |      1947 |      1947 |         1 |

### Decimal format, full name, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2603 |      2603 |      2603 |      2603 |      2603 |      2603 |      2603 |         1 |

### Decimal format, grouping never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        21 |        21 |        21 |        21 |        21 |        21 |        21 |         1 |
| Time (wall clock) (ns) * |      3524 |      3524 |      3524 |      3524 |      3524 |      3524 |      3524 |         1 |

### Decimal format, narrow, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      2411 |      2411 |      2411 |      2411 |      2411 |      2411 |      2411 |         1 |

### Decimal format, precision 1dp and accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
| Time (wall clock) (ns) * |      2631 |      2631 |      2631 |      2631 |      2631 |      2631 |      2631 |         1 |

### Decimal format, precision 1dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      2382 |      2382 |      2382 |      2382 |      2382 |      2382 |      2382 |         1 |

### Decimal format, precision 2dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      2384 |      2384 |      2384 |      2384 |      2384 |      2384 |      2384 |         1 |

### Decimal format, separator always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2522 |      2522 |      2522 |      2522 |      2522 |      2522 |      2522 |         1 |

### Decimal format, sign accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        12 |        12 |        12 |        12 |        12 |        12 |        12 |         1 |
| Time (wall clock) (ns) * |      2642 |      2642 |      2642 |      2642 |      2642 |      2642 |      2642 |         1 |

### Decimal format, sign always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2605 |      2605 |      2605 |      2605 |      2605 |      2605 |      2605 |         1 |

### Decimal format, sign never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2550 |      2550 |      2550 |      2550 |      2550 |      2550 |      2550 |         1 |

### Decimal from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         4 |
| Time (wall clock) (ns) * |       280 |       280 |       280 |       280 |       281 |       281 |       281 |         4 |

### Decimal from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         3 |
| Time (wall clock) (ns) * |       343 |       343 |       343 |       345 |       345 |       345 |       345 |         3 |

### Decimal multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         2 |
| Time (wall clock) (ns) * |       618 |       619 |       619 |       619 |       619 |       619 |       619 |         2 |

### Decimal parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         1 |
| Time (wall clock) (ns) * |      2564 |      2564 |      2564 |      2564 |      2564 |      2564 |      2564 |         1 |

### Decimal parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         3 |
| Time (wall clock) (ns) * |       336 |       336 |       336 |       337 |       337 |       337 |       337 |         3 |

### Decimal scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         4 |
| Time (wall clock) (ns) * |       270 |       270 |       271 |       271 |       271 |       271 |       271 |         4 |

### Decimal scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        83 |        83 |        83 |        83 |        83 |        83 |        83 |         1 |
| Time (wall clock) (ns) * |      5085 |      5085 |      5085 |      5085 |      5085 |      5085 |      5085 |         1 |

### Decimal subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         3 |
| Time (wall clock) (ns) * |       346 |       346 |       346 |       346 |       346 |       346 |       346 |         3 |

### Double addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Double chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       179 |
| Time (wall clock) (ns) * |         5 |         5 |         6 |         6 |         6 |         6 |         6 |       179 |

### Double comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### Double description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        21 |
| Time (wall clock) (ns) * |        48 |        48 |        48 |        48 |        48 |        49 |        49 |        21 |

### Double divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       229 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       229 |

### Double from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        14 |
| Time (wall clock) (ns) * |        73 |        73 |        73 |        73 |        73 |        73 |        73 |        14 |

### Double multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       219 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         5 |         5 |         5 |         5 |       219 |

### Double parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        14 |
| Time (wall clock) (ns) * |        75 |        75 |        75 |        75 |        76 |        76 |        76 |        14 |

### Double scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Double scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       226 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       226 |

### Double subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Engine format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         9 |
| Time (wall clock) (ns) * |       112 |       112 |       112 |       113 |       113 |       113 |       113 |         9 |

### Engine format, grouped, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       148 |       148 |       149 |       150 |       150 |       150 |       150 |         7 |

### ExchangeRate applying a margin

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        32 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        32 |        32 |        32 |

### ExchangeRate crossed

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        30 |        30 |        30 |        30 |        30 |        32 |        32 |        34 |

### FixedPoint addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### FixedPoint chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        32 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        32 |        32 |        32 |

### FixedPoint comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### FixedPoint scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       101 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        10 |        10 |       101 |

### FixedPoint scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        82 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        12 |        12 |        82 |

### FixedPoint subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       453 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       453 |

### Harness floor, a struct

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       309 |

### Harness floor, an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       545 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       545 |

### ISO currency lookup

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        91 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        91 |

### Int addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### Int chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       408 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       408 |

### Int comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### Int description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        18 |
| Time (wall clock) (ns) * |        56 |        56 |        56 |        56 |        57 |        57 |        57 |        18 |

### Int from MoneyOf minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### Int parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       129 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       129 |

### Int quotient and remainder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Int scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       453 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       453 |

### Int scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1288 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |      1288 |

### Int subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### Int128 addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       435 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       435 |

### Int128 chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       106 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        10 |       106 |

### Int128 comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       435 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       435 |

### Int128 scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       307 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       307 |

### Int128 scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       306 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       306 |

### Int128 subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       434 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       434 |

### Margin construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       123 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       123 |

### Money JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1346 |      1346 |      1346 |      1346 |      1346 |      1346 |      1346 |         1 |

### Money JSON decode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        29 |        29 |        29 |        29 |        29 |        29 |        29 |         1 |
| Time (wall clock) (ns) * |      5197 |      5197 |      5197 |      5197 |      5197 |      5197 |      5197 |         1 |

### Money JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         2 |
| Time (wall clock) (ns) * |       710 |       710 |       710 |       710 |       710 |       710 |       710 |         2 |

### Money JSON encode, major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         1 |
| Time (wall clock) (ns) * |      1049 |      1049 |      1049 |      1049 |      1049 |      1049 |      1049 |         1 |

### Money JSON encode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2761 |      2761 |      2761 |      2761 |      2761 |      2761 |      2761 |         1 |

### Money Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        36 |        36 |        37 |        37 |        29 |

### Money addition in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Money addition, separately built currencies

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### Money addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Money applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       165 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       165 |

### Money bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        57 |
| Time (wall clock) (ns) * |        18 |        18 |        18 |        18 |        18 |        18 |        18 |        57 |

### Money description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        28 |
| Time (wall clock) (ns) * |        36 |        36 |        36 |        36 |        36 |        36 |        36 |        28 |

### Money encode, no coder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       149 |       150 |       150 |       150 |       154 |       154 |       154 |         7 |

### Money encode, no coder, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         3 |
| Time (wall clock) (ns) * |       425 |       425 |       425 |       425 |       425 |       425 |       425 |         3 |

### Money format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       941 |       941 |       941 |       943 |       943 |       943 |       943 |         2 |

### Money from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      1084 |      1084 |      1084 |      1084 |      1084 |      1084 |      1084 |         1 |

### Money is less than, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       416 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         4 |       416 |

### Money is multiple, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       368 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       368 |

### Money parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        18 |        18 |        18 |        18 |        18 |        18 |        18 |         1 |
| Time (wall clock) (ns) * |      3982 |      3982 |      3982 |      3982 |      3982 |      3982 |      3982 |         1 |

### Money parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        30 |        30 |        30 |        30 |        30 |        30 |        30 |        34 |

### Money proportion, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        42 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        42 |

### Money scalar multiplication, amount times integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### Money scalar multiplication, integer times amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       278 |

### Money split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         7 |
| Time (wall clock) (ns) * |       153 |       153 |       155 |       155 |       155 |       155 |       155 |         7 |

### Money split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       101 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        10 |        10 |       101 |

### Money subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### Money total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       109 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        13 |        17 |       109 |

### Money unrounded addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       227 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       227 |

### Money unrounded applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        32 |        32 |        31 |

### Money unrounded divided by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        92 |        92 |        92 |        92 |        92 |        92 |        92 |        11 |

### Money unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         9 |
| Time (wall clock) (ns) * |       114 |       114 |       115 |       115 |       115 |       115 |       115 |         9 |

### Money unrounded plus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       118 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         9 |         9 |       118 |

### Money unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        35 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        29 |        29 |        29 |        29 |        35 |

### Money unrounded scaling by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        33 |        33 |        31 |

### Money unrounded scaling by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        15 |
| Time (wall clock) (ns) * |        67 |        67 |        67 |        67 |        67 |        67 |        67 |        15 |

### Money unrounded subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       226 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       226 |

### Money unrounded total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       104 |
| Time (wall clock) (ns) * |         9 |        10 |        10 |        10 |        10 |        10 |        10 |       104 |

### MoneyOf JSON encode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         1 |
| Time (wall clock) (ns) * |      1020 |      1020 |      1020 |      1020 |      1020 |      1020 |      1020 |         1 |

### MoneyOf Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        35 |        35 |        36 |        36 |        29 |

### MoneyOf Unrounded bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        28 |
| Time (wall clock) (ns) * |        36 |        36 |        36 |        36 |        36 |        38 |        38 |        28 |

### MoneyOf addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf attributed, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        35 |        35 |        35 |        35 |        35 |        35 |        35 |         1 |
| Time (wall clock) (μs) * |        36 |        36 |        36 |        36 |        36 |        36 |        36 |         1 |

### MoneyOf bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        65 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        16 |        16 |        16 |        16 |        65 |

### MoneyOf bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        23 |        24 |        24 |        43 |

### MoneyOf chain, rounding each step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        87 |        87 |        87 |        87 |        87 |        87 |        87 |        12 |

### MoneyOf comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       456 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       456 |

### MoneyOf converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       175 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       175 |

### MoneyOf description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        27 |
| Time (wall clock) (ns) * |        38 |        38 |        38 |        38 |        38 |        39 |        39 |        27 |

### MoneyOf format, ISO code, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       965 |       965 |       965 |       969 |       969 |       969 |       969 |         2 |

### MoneyOf format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       942 |       943 |       943 |       948 |       948 |       948 |       948 |         2 |

### MoneyOf format, every option, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1054 |      1054 |      1054 |      1054 |      1054 |      1054 |      1054 |         1 |

### MoneyOf format, full name, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
| Time (wall clock) (ns) * |      1440 |      1440 |      1440 |      1440 |      1440 |      1440 |      1440 |         1 |

### MoneyOf format, grouping never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       967 |       967 |       967 |       972 |       972 |       972 |       972 |         2 |

### MoneyOf format, increment, en_GB [ICU fallback]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        18 |        18 |        18 |        18 |        18 |        18 |        18 |         1 |
| Time (wall clock) (ns) * |      3345 |      3345 |      3345 |      3345 |      3345 |      3345 |      3345 |         1 |

### MoneyOf format, narrow, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       967 |       967 |       967 |       968 |       968 |       968 |       968 |         2 |

### MoneyOf format, precision 1dp and accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1027 |      1027 |      1027 |      1027 |      1027 |      1027 |      1027 |         1 |

### MoneyOf format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       994 |       995 |       995 |      1000 |      1000 |      1000 |      1000 |         2 |

### MoneyOf format, precision 2dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       990 |       990 |       990 |       999 |       999 |       999 |       999 |         2 |

### MoneyOf format, separator always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       946 |       946 |       946 |       952 |       952 |       952 |       952 |         2 |

### MoneyOf format, sign accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       981 |       981 |       981 |       982 |       982 |       982 |       982 |         2 |

### MoneyOf format, sign always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       967 |       967 |       967 |       972 |       972 |       972 |       972 |         2 |

### MoneyOf format, sign never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       957 |       958 |       958 |       962 |       962 |       962 |       962 |         2 |

### MoneyOf from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      1087 |      1087 |      1087 |      1087 |      1087 |      1087 |      1087 |         1 |

### MoneyOf from a negative Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      1147 |      1147 |      1147 |      1147 |      1147 |      1147 |      1147 |         1 |

### MoneyOf is multiple

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       392 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       392 |

### MoneyOf magnitude

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### MoneyOf negation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       254 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       254 |

### MoneyOf parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        18 |        18 |        18 |        18 |        18 |        18 |        18 |         1 |
| Time (wall clock) (ns) * |      4083 |      4083 |      4083 |      4083 |      4083 |      4083 |      4083 |         1 |

### MoneyOf parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        35 |        35 |        35 |        35 |        29 |

### MoneyOf parsing a large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        21 |
| Time (wall clock) (ns) * |        48 |        49 |        49 |        49 |        49 |        50 |        50 |        21 |

### MoneyOf parsing a negative amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        35 |        35 |        35 |        35 |        29 |

### MoneyOf proportion

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        24 |        24 |        24 |        43 |

### MoneyOf proportion of large amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        33 |        33 |        33 |        33 |        33 |        33 |        33 |        31 |

### MoneyOf scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       451 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       451 |

### MoneyOf scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        36 |
| Time (wall clock) (ns) * |        28 |        28 |        28 |        28 |        28 |        29 |        29 |        36 |

### MoneyOf split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         7 |
| Time (wall clock) (ns) * |       149 |       150 |       150 |       151 |       151 |       151 |       151 |         7 |

### MoneyOf split by weights that divide exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         8 |
| Time (wall clock) (ns) * |       139 |       140 |       141 |       141 |       142 |       142 |       142 |         8 |

### MoneyOf split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |        10 |        10 |        10 |        10 |       105 |

### MoneyOf split, iterating the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       253 |       253 |       253 |       253 |       253 |       253 |       253 |         4 |

### MoneyOf subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       141 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         7 |       141 |

### MoneyOf unrounded addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       232 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       232 |

### MoneyOf unrounded chain

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       169 |       169 |       169 |       170 |       170 |       170 |       170 |         6 |

### MoneyOf unrounded divided

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       174 |       174 |       174 |       174 |       174 |       174 |       174 |         6 |

### MoneyOf unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       143 |       143 |       145 |       145 |       145 |       145 |       145 |         7 |

### MoneyOf unrounded from major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       248 |       248 |       248 |       248 |       248 |       248 |       248 |         5 |

### MoneyOf unrounded minus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        14 |
| Time (wall clock) (ns) * |        74 |        74 |        74 |        75 |        75 |        75 |        75 |        14 |

### MoneyOf unrounded plus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        14 |
| Time (wall clock) (ns) * |        72 |        72 |        72 |        72 |        72 |        72 |        72 |        14 |

### MoneyOf unrounded scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        94 |        95 |        95 |        95 |        95 |        95 |        95 |        11 |

### MoneyOf unrounded subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       233 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       233 |

### MoneyOf unrounded total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        14 |
| Time (wall clock) (ns) * |        75 |        75 |        75 |        75 |        75 |        76 |        76 |        14 |

### MoneyOf unroundedBytes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        99 |        99 |       100 |       100 |       100 |       100 |       100 |        11 |

### Rate from a Double

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       247 |       247 |       247 |       247 |       247 |       247 |       247 |         5 |

### Rate from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       215 |       215 |       215 |       215 |       215 |       215 |       215 |         5 |

### Rate from a fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       165 |       165 |       166 |       166 |       166 |       166 |       166 |         7 |

### Rate from a large decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       172 |       173 |       173 |       173 |       174 |       174 |       174 |         6 |

### Rate from a negative decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       220 |       220 |       220 |       220 |       220 |       220 |       220 |         5 |

### Rate from a negative fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       191 |       192 |       192 |       192 |       192 |       192 |       192 |         6 |

### Rate from a percent string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       242 |       242 |       242 |       242 |       242 |       242 |       242 |         5 |

### Rate from a string literal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       215 |       215 |       215 |       215 |       215 |       215 |       215 |         5 |

### Rate from basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        86 |        87 |        87 |        87 |        87 |        88 |        88 |        12 |

### Rate from percent

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        93 |        93 |        93 |        93 |        93 |        93 |        93 |        11 |

### Rate to basis points, rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        36 |
| Time (wall clock) (ns) * |        28 |        28 |        28 |        28 |        28 |        28 |        28 |        36 |

### Rate to whole basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       120 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       120 |

### Split counting the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       546 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       546 |

### UnitPrice total for a fractional quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        35 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        29 |        29 |        29 |        29 |        35 |

### UnitPrice total for a whole quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        15 |
| Time (wall clock) (ns) * |        70 |        70 |        70 |        71 |        71 |        71 |        71 |        15 |

### UnitScale construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       144 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         7 |       144 |

### WeightedSplit amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        23 |
| Time (wall clock) (ns) * |        44 |        44 |        44 |        44 |        44 |        44 |        44 |        23 |

### WeightedSplit weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        23 |
| Time (wall clock) (ns) * |        44 |        44 |        44 |        44 |        45 |        45 |        45 |        23 |

### Weights construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        34 |
| Time (wall clock) (ns) * |        30 |        30 |        30 |        30 |        30 |        30 |        30 |        34 |


<!-- BENCHMARK-END -->

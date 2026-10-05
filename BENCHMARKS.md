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
| Addition | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 95 ns |
| Subtraction | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 93 ns |
| Scalar multiplication | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 75 ns |
| Scale and round | 0 instr, 7 ns | 0 instr, <1 ns | 0 instr, 3 ns | 0 instr, 1653 ns |
| Comparison | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 1 ns | 0 instr, 44 ns |
| Split into 3 | 0 instr, 5 ns | 0 instr, 2 ns | 0 instr, 3 ns | 0 instr, 824 ns |
| Chained scaling | 0 instr, 41 ns | 0 instr, 1 ns | 0 instr, 3 ns | 0 instr, 850 ns |

### Formatting, option by option, against Foundation

| Operation | Ours | Decimal | Speedup |
|:----------|----------:|----------:|----------:|
| Default | 0 instr, 879 ns | 0 instr, 4 allocs, 1185 ns | **∞** |
| Runtime currency | 0 instr, 883 ns | 0 instr, 4 allocs, 1185 ns | **∞** |
| ISO code | 0 instr, 917 ns | 0 instr, 4 allocs, 1187 ns | **∞** |
| Narrow symbol | 0 instr, 938 ns | 0 instr, 4 allocs, 1145 ns | **∞** |
| Full name | 0 instr, 1 alloc, 1051 ns | 0 instr, 5 allocs, 1264 ns | **∞** |
| Sign, never | 0 instr, 890 ns | 0 instr, 5 allocs, 1238 ns | **∞** |
| Sign, always | 0 instr, 895 ns | 0 instr, 5 allocs, 1240 ns | **∞** |
| Sign, accounting | 0 instr, 908 ns | 0 instr, 6 allocs, 1255 ns | **∞** |
| Grouping, never | 0 instr, 916 ns | 0 instr, 4 allocs, 1587 ns | **∞** |
| Decimal separator, always | 0 instr, 886 ns | 0 instr, 5 allocs, 1186 ns | **∞** |
| Precision, 2dp | 0 instr, 919 ns | 0 instr, 4 allocs, 1145 ns | **∞** |
| Precision, 1dp | 0 instr, 944 ns | 0 instr, 4 allocs, 1134 ns | **∞** |
| Precision and accounting | 0 instr, 1001 ns | 0 instr, 6 allocs, 1253 ns | **∞** |
| Every option | 0 instr, 977 ns | 0 instr, 7 allocs, 1408 ns | **∞** |
| Rounding increment | 0 instr, 4 allocs, 1389 ns | n/a | n/a |
| Attributed | 0 instr, 35 allocs, 19000 ns | 0 instr, 36 allocs, 13000 ns | **∞** |
| Parse | 0 instr, 5 allocs, 1938 ns | 0 instr, 5 allocs, 1328 ns | **∞** |

### Typed currency against runtime currency

| Operation | Ours | Money | Speedup |
|:----------|----------:|----------:|----------:|
| Addition | 0 instr, 1 ns | 0 instr, 2 ns | **∞** |
| Subtraction | 0 instr, 1 ns | 0 instr, 2 ns | **∞** |
| Scalar multiplication | 0 instr, 1 ns | 0 instr, 2 ns | **∞** |
| Applying a rate | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Equality | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Hashing | 0 instr, 18 ns | 0 instr, 20 ns | **∞** |
| Construction, checked | 0 instr, 2 ns | 0 instr, 2 ns | **∞** |
| Description | 0 instr, 22 ns | 0 instr, 22 ns | **∞** |
| Parsing | 0 instr, 10 ns | 0 instr, 15 ns | **∞** |
| Proportion | 0 instr, 6 ns | 0 instr, 6 ns | **∞** |
| Split into 3 | 0 instr, 5 ns | 0 instr, 5 ns | **∞** |
| Split by weights | 0 instr, 4 allocs, 101 ns | 0 instr, 4 allocs, 104 ns | **∞** |
| Total of 10 | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Bytes encode | 0 instr, 11 ns | 0 instr, 9 ns | **∞** |
| Bytes decode | 0 instr, 7 ns | 0 instr, 9 ns | **∞** |
| Unrounded addition | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Unrounded subtraction | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Unrounded plus settled | 0 instr, 3 ns | 0 instr, 2 ns | **∞** |
| Unrounded minus settled | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Unrounded scaling by a rate | 0 instr, 12 ns | 0 instr, 12 ns | **∞** |
| Unrounded times an integer | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded divided | 0 instr, 8 ns | 0 instr, 8 ns | **∞** |
| Unrounded divided exactly | 0 instr, 7 ns | 0 instr, 7 ns | **∞** |
| Unrounded rounded | 0 instr, 6 ns | 0 instr, 7 ns | **∞** |
| Unrounded total of 10 | 0 instr, 3 ns | 0 instr, 5 ns | **∞** |
| Unrounded bytes decode | 0 instr, 19 ns | 0 instr, 19 ns | **∞** |

### What the measurement itself costs

| Operation | Ours |
|:----------|----------:|
| Handing an integer to the harness | 0 instr, 1 ns |
| Handing a struct to the harness | 0 instr, 2 ns |

### SwiftMoney's own operations

| Operation | Ours |
|:----------|----------:|
| Addition, throwing | 0 instr, 2 ns |
| Widening to unrounded | 0 instr, 2 ns |
| Scale, leaving it unrounded | 0 instr, 12 ns |
| Unrounded addition | 0 instr, 3 ns |
| Chained scaling, rounding each step | 0 instr, 26 ns |
| Rate from basis points | 0 instr, 2 ns |
| Rate from a decimal string | 0 instr, 32 ns |
| Exchange rate construction | 0 instr, 12 ns |
| Split into 3, runtime currency | 0 instr, 5 ns |
| Split, iterating the parts | 0 instr, 6 ns |
| Split into 1000, materialized | 0 instr, 1 alloc, 463 ns |
| Split by 10 weights | 0 instr, 4 allocs, 174 ns |
| Total of 10 | 0 instr, 4 ns |
| Total of 1000 | 0 instr, 230 ns |
| Currency code validation | 0 instr, 14 ns |
| Proportion | 0 instr, 6 ns |
| Proportion of large amounts | 0 instr, 8 ns |
| Addition, separately built currencies | 0 instr, 2 ns |
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
Host 'runnervm8df0l' with 4 'x86_64' processors with 15 GB memory, running:
#22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026
```
## SwiftMoneyBenchmarks

### AnyCurrency storage for a custom field

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       207 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       207 |

### ClosedMoneyRange clamped, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       329 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       329 |

### ClosedMoneyRange construction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       361 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         5 |       361 |

### ClosedMoneyRange contains a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       348 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       348 |

### ClosedMoneyRange contains a half-open range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       351 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       351 |

### ClosedMoneyRange contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       349 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       349 |

### ClosedMoneyRange currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       699 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       699 |

### ClosedMoneyRange debug description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        12 |
| Time (wall clock) (ns) * |        84 |        84 |        84 |        84 |        85 |       114 |       114 |        12 |

### ClosedMoneyRange description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        13 |
| Time (wall clock) (ns) * |        79 |        79 |        79 |        80 |        80 |        85 |        85 |        13 |

### ClosedMoneyRange from a half-open range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       438 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       438 |

### ClosedMoneyRange from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       710 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       710 |

### ClosedMoneyRange from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       364 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       364 |

### ClosedMoneyRange is empty

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |     10000 |
| Time (wall clock) (ns) * |         0 |         0 |         0 |         0 |         0 |         0 |         0 |     10000 |

### ClosedMoneyRange lower bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       477 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       477 |

### ClosedMoneyRange overlaps a half-open range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       348 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       348 |

### ClosedMoneyRange overlaps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       347 |

### ClosedMoneyRange steps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       348 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       348 |

### ClosedMoneyRange upper bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       415 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         4 |         5 |       415 |

### ClosedRange from ClosedMoneyRange, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       427 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         3 |         3 |       427 |

### ClosedRange from a half-open range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       479 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       479 |

### ClosedRange from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       363 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         6 |       363 |

### ClosedRange of MoneyOf clamped

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       343 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       343 |

### ClosedRange of MoneyOf construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       366 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       366 |

### ClosedRange of MoneyOf contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       349 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       349 |

### ClosedRange of MoneyOf contains a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       359 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       359 |

### ClosedRange of MoneyOf contains a half-open range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       350 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       350 |

### ClosedRange of MoneyOf overlaps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       361 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       361 |

### ClosedRange of MoneyOf steps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       341 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       341 |

### Control JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         4 |
| Time (wall clock) (ns) * |       296 |       296 |       296 |       300 |       303 |       303 |       303 |         4 |

### Control JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         5 |
| Time (wall clock) (ns) * |       245 |       245 |       245 |       246 |       249 |       249 |       249 |         5 |

### Currency construction, custom

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       220 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         5 |         5 |         6 |         7 |       220 |

### Currency description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       108 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |        10 |        10 |        10 |       108 |

### Currency equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       900 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       900 |

### CurrencyCode description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        78 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        13 |        14 |        14 |        78 |

### CurrencyCode equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       719 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       719 |

### CurrencyCode validation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        70 |
| Time (wall clock) (ns) * |        14 |        14 |        14 |        14 |        15 |        15 |        15 |        70 |

### CurrencyCode validation, eight characters

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        25 |        25 |        43 |

### CurrencyCode validation, lowercase

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        79 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        13 |        14 |        14 |        79 |

### CurrencyType storage for a field

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        45 |
| Time (wall clock) (ns) * |        22 |        22 |        22 |        22 |        23 |        23 |        23 |        45 |

### Decimal JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         3 |
| Time (wall clock) (ns) * |       377 |       377 |       379 |       385 |       385 |       385 |       385 |         3 |

### Decimal JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         3 |
| Time (wall clock) (ns) * |       392 |       392 |       393 |       393 |       393 |       393 |       393 |         3 |

### Decimal addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        95 |        95 |        95 |        95 |        98 |        99 |        99 |        11 |

### Decimal attributed, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        36 |        36 |        36 |        36 |        36 |        36 |        36 |         1 |
| Time (wall clock) (μs) * |        13 |        13 |        13 |        13 |        13 |        13 |        13 |         1 |

### Decimal chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       850 |       850 |       850 |       854 |       854 |       854 |       854 |         2 |

### Decimal comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        23 |
| Time (wall clock) (ns) * |        43 |        44 |        44 |        45 |        45 |        47 |        47 |        23 |

### Decimal description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       168 |       169 |       169 |       177 |       214 |       214 |       214 |         6 |

### Decimal divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       824 |       824 |       824 |       836 |       836 |       836 |       836 |         2 |

### Decimal format, ISO code, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1187 |      1187 |      1187 |      1187 |      1187 |      1187 |      1187 |         1 |

### Decimal format, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1185 |      1185 |      1185 |      1185 |      1185 |      1185 |      1185 |         1 |

### Decimal format, every option, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         1 |
| Time (wall clock) (ns) * |      1408 |      1408 |      1408 |      1408 |      1408 |      1408 |      1408 |         1 |

### Decimal format, full name, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1264 |      1264 |      1264 |      1264 |      1264 |      1264 |      1264 |         1 |

### Decimal format, grouping never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1587 |      1587 |      1587 |      1587 |      1587 |      1587 |      1587 |         1 |

### Decimal format, narrow, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1145 |      1145 |      1145 |      1145 |      1145 |      1145 |      1145 |         1 |

### Decimal format, precision 1dp and accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1253 |      1253 |      1253 |      1253 |      1253 |      1253 |      1253 |         1 |

### Decimal format, precision 1dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1134 |      1134 |      1134 |      1134 |      1134 |      1134 |      1134 |         1 |

### Decimal format, precision 2dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1145 |      1145 |      1145 |      1145 |      1145 |      1145 |      1145 |         1 |

### Decimal format, separator always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1186 |      1186 |      1186 |      1186 |      1186 |      1186 |      1186 |         1 |

### Decimal format, sign accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1255 |      1255 |      1255 |      1255 |      1255 |      1255 |      1255 |         1 |

### Decimal format, sign always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1240 |      1240 |      1240 |      1240 |      1240 |      1240 |      1240 |         1 |

### Decimal format, sign never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1238 |      1238 |      1238 |      1238 |      1238 |      1238 |      1238 |         1 |

### Decimal from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       119 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         9 |         9 |         9 |       119 |

### Decimal from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       150 |       150 |       150 |       150 |       150 |       150 |       150 |         7 |

### Decimal multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       185 |       185 |       185 |       186 |       191 |       191 |       191 |         6 |

### Decimal parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1328 |      1328 |      1328 |      1328 |      1328 |      1328 |      1328 |         1 |

### Decimal parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       151 |       151 |       152 |       155 |       160 |       160 |       160 |         7 |

### Decimal scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        14 |
| Time (wall clock) (ns) * |        74 |        75 |        75 |        77 |        79 |        87 |        87 |        14 |

### Decimal scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1653 |      1653 |      1653 |      1653 |      1653 |      1653 |      1653 |         1 |

### Decimal subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        92 |        93 |        93 |        95 |        95 |        95 |        95 |        11 |

### Double addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       724 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       724 |

### Double chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       364 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       364 |

### Double comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       720 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       720 |

### Double description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        37 |
| Time (wall clock) (ns) * |        27 |        27 |        27 |        27 |        28 |        29 |        29 |        37 |

### Double divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       369 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       369 |

### Double from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        59 |
| Time (wall clock) (ns) * |        17 |        17 |        17 |        17 |        17 |        18 |        18 |        59 |

### Double multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       357 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       357 |

### Double parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        67 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        15 |        15 |        22 |        22 |        67 |

### Double scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       724 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       724 |

### Double scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       368 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       368 |

### Double subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       723 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       723 |

### Engine format, accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        84 |        84 |        84 |        85 |        86 |        89 |        89 |        12 |

### Engine format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        61 |        61 |        61 |        63 |        65 |        77 |        77 |        16 |

### Engine format, grouped, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        87 |        87 |        87 |        88 |        89 |        89 |        89 |        12 |

### Engine format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        66 |        66 |        66 |        66 |        68 |        70 |        70 |        16 |

### ExchangeRate applying a margin

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        77 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        13 |        13 |        13 |        77 |

### ExchangeRate construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        85 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        85 |

### ExchangeRate construction, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        85 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        14 |        14 |        85 |

### ExchangeRate crossed

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        84 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        84 |

### FixedPoint addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       684 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       684 |

### FixedPoint chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        24 |        24 |        24 |        24 |        43 |

### FixedPoint comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       712 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       712 |

### FixedPoint scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       188 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       188 |

### FixedPoint scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       141 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       141 |

### FixedPoint subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       685 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         3 |       685 |

### FractionLength construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       460 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         4 |         5 |       460 |

### Harness floor, a struct

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       542 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       542 |

### Harness floor, an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1016 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |      1016 |

### ISO currency lookup

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       186 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       186 |

### Int addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       715 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       715 |

### Int chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       772 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       772 |

### Int comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       714 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       714 |

### Int description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        33 |
| Time (wall clock) (ns) * |        30 |        30 |        30 |        30 |        31 |        35 |        35 |        33 |

### Int from MoneyOf minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       420 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         4 |         6 |       420 |

### Int hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        56 |
| Time (wall clock) (ns) * |        18 |        18 |        18 |        18 |        19 |        19 |        19 |        56 |

### Int parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       221 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         5 |         5 |         5 |         5 |       221 |

### Int quotient and remainder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       534 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       534 |

### Int scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       708 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       708 |

### Int scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      2235 |
| Time (wall clock) (ns) * |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      2235 |

### Int subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       706 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         3 |       706 |

### Int128 addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       685 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       685 |

### Int128 chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       196 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         6 |       196 |

### Int128 comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       692 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       692 |

### Int128 scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       465 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       465 |

### Int128 scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       548 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       548 |

### Int128 subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       691 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       691 |

### Margin construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       232 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       232 |

### Money JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       613 |       613 |       613 |       619 |       619 |       619 |       619 |         2 |

### Money JSON decode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        24 |        24 |        24 |        24 |        24 |        24 |        24 |         1 |
| Time (wall clock) (ns) * |      2709 |      2709 |      2709 |      2709 |      2709 |      2709 |      2709 |         1 |

### Money JSON decode, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         2 |
| Time (wall clock) (ns) * |       874 |       874 |       874 |       878 |       878 |       878 |       878 |         2 |

### Money JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         3 |
| Time (wall clock) (ns) * |       349 |       349 |       356 |       382 |       382 |       382 |       382 |         3 |

### Money JSON encode, major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       564 |       564 |       564 |       592 |       592 |       592 |       592 |         2 |

### Money JSON encode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      1497 |      1497 |      1497 |      1497 |      1497 |      1497 |      1497 |         1 |

### Money Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        52 |
| Time (wall clock) (ns) * |        19 |        19 |        19 |        20 |        20 |        20 |        20 |        52 |

### Money addition in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       536 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       536 |

### Money addition, separately built currencies

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       538 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       538 |

### Money addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       484 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       484 |

### Money applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       308 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         6 |       308 |

### Money bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       114 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |         9 |       114 |

### Money bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       111 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        11 |       111 |

### Money clamped to a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       433 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       433 |

### Money clamped to a lower bound, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       469 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         5 |       469 |

### Money clamped to an upper bound, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       476 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       476 |

### Money description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        47 |
| Time (wall clock) (ns) * |        22 |        22 |        22 |        22 |        22 |        23 |        23 |        47 |

### Money encode, no coder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        82 |        83 |        83 |        84 |        85 |        91 |        91 |        12 |

### Money encode, no coder, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         4 |
| Time (wall clock) (ns) * |       280 |       280 |       282 |       282 |       282 |       282 |       282 |         4 |

### Money equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       358 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       358 |

### Money format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       883 |       883 |       883 |       888 |       888 |       888 |       888 |         2 |

### Money from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       351 |       351 |       353 |       353 |       353 |       353 |       353 |         3 |

### Money from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       477 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       477 |

### Money hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        50 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        20 |        20 |        20 |        50 |

### Money init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       462 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       462 |

### Money init major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       316 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         6 |         6 |       316 |

### Money init major units, Int64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       345 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       345 |

### Money init major units, UInt32

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       347 |

### Money is less than, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       665 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       665 |

### Money is multiple, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       638 |
| Time (wall clock) (ns) * |         1 |         1 |         2 |         2 |         2 |         2 |         2 |       638 |

### Money parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1877 |      1877 |      1877 |      1877 |      1877 |      1877 |      1877 |         1 |

### Money parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        66 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        15 |        15 |        17 |        17 |        66 |

### Money parsing, caller's currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        76 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        13 |        20 |        20 |        76 |

### Money parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        71 |
| Time (wall clock) (ns) * |        14 |        14 |        14 |        14 |        14 |        15 |        15 |        71 |

### Money proportion, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       157 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         7 |         8 |         8 |       157 |

### Money scalar multiplication, amount times integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       466 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         4 |         4 |       466 |

### Money scalar multiplication, integer times amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       479 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       479 |

### Money split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |        10 |
| Time (wall clock) (ns) * |       104 |       104 |       104 |       104 |       104 |       105 |       105 |        10 |

### Money split equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       368 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       368 |

### Money split hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        25 |        25 |        26 |        26 |        41 |

### Money split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       616 |       617 |       617 |       625 |       625 |       625 |       625 |         2 |

### Money split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       194 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         9 |        10 |       194 |

### Money subtraction in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       689 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       689 |

### Money subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       473 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       473 |

### Money total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       271 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       271 |

### Money total of 1000, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       307 |       307 |       310 |       314 |       318 |       318 |       318 |         4 |

### Money unrounded addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       348 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         6 |       348 |

### Money unrounded applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        80 |
| Time (wall clock) (ns) * |        12 |        12 |        13 |        13 |        13 |        14 |        14 |        80 |

### Money unrounded divided by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       128 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       128 |

### Money unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       136 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         9 |       136 |

### Money unrounded minus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       354 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       354 |

### Money unrounded plus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       485 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       485 |

### Money unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       137 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       137 |

### Money unrounded scaling by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        82 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        82 |

### Money unrounded scaling by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       269 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       269 |

### Money unrounded subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       351 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         5 |       351 |

### Money unrounded total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       200 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       200 |

### Money.Steps bounds

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       712 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       712 |

### Money.Steps contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       234 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       234 |

### Money.Steps firstIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       231 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       231 |

### Money.Steps from bounds and step, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       235 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       235 |

### Money.Steps from typed steps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       480 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       480 |

### Money.Steps index for an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       203 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       203 |

### Money.Steps index for an amount, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       151 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |        11 |        12 |       151 |

### Money.Steps index for an amount, ties away from zero, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       153 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         7 |         7 |         7 |         7 |       153 |

### Money.Steps index offset by, limited by

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       423 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       423 |

### Money.Steps lastIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       226 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         5 |         5 |         5 |       226 |

### Money.Steps subscript

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       437 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       437 |

### Money.Steps walk, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       145 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         7 |       145 |

### Money.Steps.Selection amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       437 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       437 |

### Money.Steps.Selection from a typed selection

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       481 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       481 |

### Money.Steps.Selection from an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       179 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |        10 |        11 |       179 |

### Money.Steps.Selection from an amount, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       141 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       141 |

### Money.Steps.Selection from an amount, ties away from zero, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       138 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       138 |

### Money.Steps.Selection selecting an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       197 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       197 |

### Money.Steps.Selection selecting an amount, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       142 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         7 |       142 |

### Money.Steps.Selection selecting an amount, ties away from zero, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       137 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       137 |

### Money.Steps.Selection selecting an index

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       439 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         3 |         3 |       439 |

### Money.Stride from a typed stride

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       480 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       480 |

### Money.Stride init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       417 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         5 |         6 |       417 |

### Money.Stride major unit of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       335 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       335 |

### Money.Stride major unit of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       311 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       311 |

### Money.Stride major units of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       334 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       334 |

### Money.Stride major units of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       334 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       334 |

### Money.Stride minor unit of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       470 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       470 |

### Money.Stride minor unit of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       480 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       480 |

### Money.Stride minor units of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       469 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       469 |

### Money.Stride minor units of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       459 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         4 |         5 |       459 |

### MoneyCodingFormat custom fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         5 |
| Time (wall clock) (ns) * |       231 |       240 |       244 |       244 |       245 |       245 |       245 |         5 |

### MoneyLocalization moneyFormat, ISO code, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       482 |       482 |       485 |       505 |       505 |       505 |       505 |         3 |

### MoneyLocalization moneyFormat, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       473 |       473 |       473 |       479 |       479 |       479 |       479 |         3 |

### MoneyOf JSON decode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         2 |
| Time (wall clock) (ns) * |       927 |       928 |       928 |       946 |       946 |       946 |       946 |         2 |

### MoneyOf JSON encode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       534 |       535 |       535 |       536 |       536 |       536 |       536 |         2 |

### MoneyOf Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        53 |
| Time (wall clock) (ns) * |        18 |        18 |        19 |        19 |        19 |        31 |        31 |        53 |

### MoneyOf Unrounded bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        54 |
| Time (wall clock) (ns) * |        18 |        18 |        19 |        19 |        19 |        21 |        21 |        54 |

### MoneyOf addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       691 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         3 |       691 |

### MoneyOf addition in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       696 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         3 |       696 |

### MoneyOf addition near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      3631 |
| Time (wall clock) (ns) * |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      3631 |

### MoneyOf applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       306 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       306 |

### MoneyOf attributed, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        35 |        35 |        35 |        35 |        35 |        35 |        35 |         1 |
| Time (wall clock) (μs) * |        19 |        19 |        19 |        19 |        19 |        19 |        19 |         1 |

### MoneyOf bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       144 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       144 |

### MoneyOf bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        94 |
| Time (wall clock) (ns) * |        10 |        10 |        11 |        11 |        11 |        11 |        11 |        94 |

### MoneyOf bytes encode, extremes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        97 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        11 |        11 |        11 |        97 |

### MoneyOf chain, rounding each step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        38 |
| Time (wall clock) (ns) * |        26 |        26 |        26 |        26 |        27 |        28 |        28 |        38 |

### MoneyOf clamped to a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       297 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       297 |

### MoneyOf clamped to a lower bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       475 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       475 |

### MoneyOf clamped to an upper bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       428 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       428 |

### MoneyOf comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       678 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         2 |         3 |         3 |       678 |

### MoneyOf converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       288 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       288 |

### MoneyOf currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1055 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |      1055 |

### MoneyOf description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        46 |
| Time (wall clock) (ns) * |        22 |        22 |        22 |        22 |        22 |        23 |        23 |        46 |

### MoneyOf description, large negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        12 |
| Time (wall clock) (ns) * |        82 |        83 |        83 |        83 |        85 |        87 |        87 |        12 |

### MoneyOf equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       359 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       359 |

### MoneyOf format, ISO code, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       917 |       917 |       917 |       920 |       920 |       920 |       920 |         2 |

### MoneyOf format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       879 |       879 |       879 |       896 |       896 |       896 |       896 |         2 |

### MoneyOf format, every option, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       977 |       977 |       977 |       992 |       992 |       992 |       992 |         2 |

### MoneyOf format, full name, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
| Time (wall clock) (ns) * |      1051 |      1051 |      1051 |      1051 |      1051 |      1051 |      1051 |         1 |

### MoneyOf format, grouping never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       916 |       916 |       916 |       940 |       940 |       940 |       940 |         2 |

### MoneyOf format, increment, en_GB [ICU fallback]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1389 |      1389 |      1389 |      1389 |      1389 |      1389 |      1389 |         1 |

### MoneyOf format, narrow, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       938 |       938 |       938 |       940 |       940 |       940 |       940 |         2 |

### MoneyOf format, precision 1dp and accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1001 |      1001 |      1001 |      1001 |      1001 |      1001 |      1001 |         1 |

### MoneyOf format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       943 |       944 |       944 |       946 |       946 |       946 |       946 |         2 |

### MoneyOf format, precision 2dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       918 |       919 |       919 |       928 |       928 |       928 |       928 |         2 |

### MoneyOf format, separator always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       885 |       886 |       886 |       888 |       888 |       888 |       888 |         2 |

### MoneyOf format, sign accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       907 |       908 |       908 |       915 |       915 |       915 |       915 |         2 |

### MoneyOf format, sign always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       894 |       895 |       895 |       927 |       927 |       927 |       927 |         2 |

### MoneyOf format, sign never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       890 |       890 |       890 |       891 |       891 |       891 |       891 |         2 |

### MoneyOf from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       350 |       350 |       352 |       381 |       381 |       381 |       381 |         3 |

### MoneyOf from Money, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       485 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       485 |

### MoneyOf from a negative Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       381 |       381 |       389 |       398 |       398 |       398 |       398 |         3 |

### MoneyOf hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        57 |
| Time (wall clock) (ns) * |        18 |        18 |        18 |        18 |        18 |        19 |        19 |        57 |

### MoneyOf init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       491 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         4 |         4 |       491 |

### MoneyOf init major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       359 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       359 |

### MoneyOf init major units, Int64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       365 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       365 |

### MoneyOf init major units, UInt32

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       363 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       363 |

### MoneyOf is multiple

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       703 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       703 |

### MoneyOf is negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       694 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         3 |       694 |

### MoneyOf is positive

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       704 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       704 |

### MoneyOf is zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       718 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       718 |

### MoneyOf magnitude

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       431 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       431 |

### MoneyOf negation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       477 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       477 |

### MoneyOf parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1938 |      1938 |      1938 |      1938 |      1938 |      1938 |      1938 |         1 |

### MoneyOf parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        97 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        11 |        11 |        11 |        97 |

### MoneyOf parsing a large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        42 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        25 |        25 |        25 |        42 |

### MoneyOf parsing a negative amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       116 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |         9 |       116 |

### MoneyOf parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        82 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        82 |

### MoneyOf proportion

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       166 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         7 |       166 |

### MoneyOf proportion of large amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       132 |
| Time (wall clock) (ns) * |         7 |         7 |         8 |         8 |         8 |         8 |         8 |       132 |

### MoneyOf scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       709 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       709 |

### MoneyOf scalar multiplication in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       483 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       483 |

### MoneyOf scalar multiplication near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       478 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       478 |

### MoneyOf scalar multiplication, Int32 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       395 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         3 |         3 |       395 |

### MoneyOf scalar multiplication, Int64 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       706 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       706 |

### MoneyOf scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       152 |
| Time (wall clock) (ns) * |         6 |         6 |         7 |         7 |         7 |         7 |         7 |       152 |

### MoneyOf scaled and rounded, large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       138 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |        11 |        13 |       138 |

### MoneyOf split by 10 weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         6 |
| Time (wall clock) (ns) * |       173 |       173 |       174 |       177 |       177 |       177 |       177 |         6 |

### MoneyOf split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |        10 |
| Time (wall clock) (ns) * |       100 |       100 |       101 |       101 |       101 |       101 |       101 |        10 |

### MoneyOf split by weights that divide exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |        17 |
| Time (wall clock) (ns) * |        60 |        60 |        60 |        62 |        63 |        64 |        64 |        17 |

### MoneyOf split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         3 |
| Time (wall clock) (ns) * |       461 |       461 |       463 |       463 |       463 |       463 |       463 |         3 |

### MoneyOf split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       211 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       211 |

### MoneyOf split, iterating the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       158 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         7 |         7 |         7 |       158 |

### MoneyOf subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       710 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         3 |       710 |

### MoneyOf total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       268 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         6 |         7 |       268 |

### MoneyOf total of 1000

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       230 |       230 |       230 |       231 |       231 |       231 |       231 |         5 |

### MoneyOf unrounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       475 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       475 |

### MoneyOf unrounded addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       346 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       346 |

### MoneyOf unrounded chain

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        25 |
| Time (wall clock) (ns) * |        41 |        41 |        41 |        41 |        42 |        47 |        47 |        25 |

### MoneyOf unrounded converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        72 |
| Time (wall clock) (ns) * |        14 |        14 |        14 |        14 |        14 |        16 |        16 |        72 |

### MoneyOf unrounded divided

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       123 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |        13 |        15 |       123 |

### MoneyOf unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       142 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         7 |       142 |

### MoneyOf unrounded from major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        35 |        36 |        37 |        37 |        29 |

### MoneyOf unrounded from minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       479 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       479 |

### MoneyOf unrounded minus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       358 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       358 |

### MoneyOf unrounded plus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       358 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       358 |

### MoneyOf unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       156 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         7 |         9 |         9 |       156 |

### MoneyOf unrounded scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        84 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        14 |        14 |        84 |

### MoneyOf unrounded subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       354 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       354 |

### MoneyOf unrounded times an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       271 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         6 |         8 |       271 |

### MoneyOf unrounded total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       283 |

### MoneyOf unroundedBytes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        55 |
| Time (wall clock) (ns) * |        18 |        18 |        18 |        18 |        19 |        19 |        19 |        55 |

### MoneyOf.Steps bounds

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       474 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         5 |       474 |

### MoneyOf.Steps contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       240 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       240 |

### MoneyOf.Steps firstIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       229 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       229 |

### MoneyOf.Steps from bounds and step, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       239 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       239 |

### MoneyOf.Steps from runtime steps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       484 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       484 |

### MoneyOf.Steps index for an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       164 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       164 |

### MoneyOf.Steps index for an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       208 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       208 |

### MoneyOf.Steps index for an amount, ties away from zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       162 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       162 |

### MoneyOf.Steps index offset by, limited by

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       432 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       432 |

### MoneyOf.Steps lastIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       231 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       231 |

### MoneyOf.Steps subscript

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       437 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       437 |

### MoneyOf.Steps walk, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       144 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |        10 |        10 |       144 |

### MoneyOf.Steps.Selection amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       481 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       481 |

### MoneyOf.Steps.Selection from a runtime selection, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       481 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       481 |

### MoneyOf.Steps.Selection from an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       146 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       146 |

### MoneyOf.Steps.Selection from an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       194 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         6 |       194 |

### MoneyOf.Steps.Selection from an amount, ties away from zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       145 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         7 |       145 |

### MoneyOf.Steps.Selection selecting an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       153 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         7 |         7 |         7 |       153 |

### MoneyOf.Steps.Selection selecting an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       203 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       203 |

### MoneyOf.Steps.Selection selecting an amount, ties away from zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       156 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         7 |         7 |         7 |       156 |

### MoneyOf.Steps.Selection selecting an index

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       431 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       431 |

### MoneyOf.Stride from a runtime stride, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       484 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       484 |

### MoneyOf.Stride init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       483 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       483 |

### MoneyOf.Stride major unit

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       360 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       360 |

### MoneyOf.Stride major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       355 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       355 |

### MoneyOf.Stride minor unit

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       538 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       538 |

### MoneyOf.Stride minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       532 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       532 |

### MoneyRange clamped, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       326 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       326 |

### MoneyRange construction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       361 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       361 |

### MoneyRange contains a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       349 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       349 |

### MoneyRange contains a half-open range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       360 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       360 |

### MoneyRange contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       350 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       350 |

### MoneyRange currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       689 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       689 |

### MoneyRange debug description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        12 |
| Time (wall clock) (ns) * |        84 |        84 |        85 |        87 |        87 |        89 |        89 |        12 |

### MoneyRange description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        13 |
| Time (wall clock) (ns) * |        78 |        78 |        79 |        81 |        83 |       108 |       108 |        13 |

### MoneyRange from a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       435 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       435 |

### MoneyRange from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       704 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       704 |

### MoneyRange from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       364 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       364 |

### MoneyRange is empty

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       692 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       692 |

### MoneyRange lower bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       464 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         4 |         4 |       464 |

### MoneyRange overlaps a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       347 |

### MoneyRange overlaps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       346 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         5 |         6 |       346 |

### MoneyRange upper bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       432 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       432 |

### NSDecimalNumber addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         9 |
| Time (wall clock) (ns) * |       117 |       117 |       119 |       123 |       148 |       148 |       148 |         9 |

### NSDecimalNumber comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        22 |
| Time (wall clock) (ns) * |        46 |        46 |        46 |        47 |        47 |        49 |        49 |        22 |

### NSDecimalNumber multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         5 |
| Time (wall clock) (ns) * |       240 |       241 |       241 |       242 |       243 |       243 |       243 |         5 |

### NSDecimalNumber parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         6 |
| Time (wall clock) (ns) * |       168 |       168 |       168 |       169 |       169 |       169 |       169 |         6 |

### PartCount construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       536 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         4 |       536 |

### PartialMoneyRangeFrom construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       715 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       715 |

### PartialMoneyRangeFrom contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       364 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       364 |

### PartialMoneyRangeFrom currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       712 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         3 |       712 |

### PartialMoneyRangeFrom from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       310 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       310 |

### PartialMoneyRangeThrough construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       709 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       709 |

### PartialMoneyRangeThrough contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       354 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         5 |       354 |

### PartialMoneyRangeThrough currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       715 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       715 |

### PartialMoneyRangeThrough from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       310 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         5 |         7 |       310 |

### PartialMoneyRangeUpTo construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       707 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       707 |

### PartialMoneyRangeUpTo contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       358 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       358 |

### PartialMoneyRangeUpTo currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       690 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         3 |       690 |

### PartialMoneyRangeUpTo from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       303 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         6 |         7 |       303 |

### PartialRangeFrom from PartialMoneyRangeFrom, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       243 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       243 |

### PartialRangeThrough from PartialMoneyRangeThrough, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       240 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       240 |

### PartialRangeUpTo from PartialMoneyRangeUpTo, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       240 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       240 |

### PartialRangeUpTo of MoneyOf construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       481 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       481 |

### PartialRangeUpTo of MoneyOf contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       354 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       354 |

### Range from MoneyRange, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       462 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         4 |         4 |       462 |

### Range from a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       426 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       426 |

### Range from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       355 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       355 |

### Range of MoneyOf construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       358 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       358 |

### Range of MoneyOf contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       356 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       356 |

### Rate equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       849 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       849 |

### Rate from a Double

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |       102 |       103 |       103 |       104 |       104 |       104 |       104 |        10 |

### Rate from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        33 |        34 |        35 |        35 |        31 |

### Rate from a fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        83 |        84 |        84 |        85 |        86 |        91 |        91 |        12 |

### Rate from a large decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        87 |        87 |        87 |        88 |        89 |        89 |        89 |        12 |

### Rate from a negative decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        36 |        36 |        40 |        40 |        29 |

### Rate from a negative fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        96 |        97 |        98 |        98 |        99 |       101 |       101 |        11 |

### Rate from a percent string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        20 |
| Time (wall clock) (ns) * |        49 |        49 |        50 |        51 |        51 |        53 |        53 |        20 |

### Rate from a string literal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        35 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        29 |        30 |        31 |        31 |        35 |

### Rate from basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       480 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       480 |

### Rate from percent

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       429 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       429 |

### Rate to basis points, rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       124 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |        13 |        14 |       124 |

### Rate to whole basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       152 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         7 |         7 |         7 |         7 |       152 |

### Split counting the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       683 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       683 |

### Split equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       344 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       344 |

### Split hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        44 |
| Time (wall clock) (ns) * |        22 |        23 |        23 |        23 |        24 |        24 |        24 |        44 |

### UnitPrice total for a fractional quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        84 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        12 |        12 |        84 |

### UnitPrice total for a whole quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       310 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       310 |

### UnitScale construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       284 |

### UnitScale from decimal places

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       483 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       483 |

### Weight construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       537 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       537 |

### WeightedSplit amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        50 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        21 |        21 |        21 |        50 |

### WeightedSplit count

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       707 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         2 |         2 |       707 |

### WeightedSplit hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        38 |
| Time (wall clock) (ns) * |        27 |        27 |        27 |        27 |        27 |        28 |        28 |        38 |

### WeightedSplit weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        50 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        21 |        24 |        24 |        50 |

### Weights construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        66 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        15 |        15 |        16 |        16 |        66 |

### stride through Int64, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       204 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         6 |       204 |

### stride through Money contains, between steps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       220 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         5 |         5 |         5 |         5 |       220 |

### stride through Money contains, in another currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       364 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       364 |

### stride through Money contains, on a step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       217 |
| Time (wall clock) (ns) * |         4 |         4 |         5 |         5 |         5 |         5 |         5 |       217 |

### stride through Money contains, past the end

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       316 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       316 |

### stride through Money, £250 by £25, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       178 |
| Time (wall clock) (ns) * |         5 |         5 |         6 |         6 |         6 |         6 |         6 |       178 |

### stride through MoneyOf contains, between steps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       228 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       228 |

### stride through MoneyOf contains, on a step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       228 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       228 |

### stride through MoneyOf contains, past the end

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       338 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       338 |

### stride through MoneyOf underestimatedCount, Int.max

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       253 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       253 |

### stride through MoneyOf underestimatedCount, eleven amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       335 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         6 |       335 |

### stride through MoneyOf, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       190 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       190 |

### stride to Money, £250 by £25, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       184 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         6 |         6 |         7 |         8 |       184 |

### stride to MoneyOf, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       195 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       195 |


<!-- BENCHMARK-END -->

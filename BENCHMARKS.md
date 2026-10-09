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
| Addition | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 133 ns |
| Subtraction | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 129 ns |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 105 ns |
| Scale and round | 0 instr, 8 ns | 0 instr, 1 ns | 0 instr, 3 ns | 0 instr, 2444 ns |
| Comparison | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 62 ns |
| Split into 3 | 0 instr, 4 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 1219 ns |
| Chained scaling | 0 instr, 49 ns | 0 instr, 1 ns | 0 instr, 3 ns | 0 instr, 1286 ns |

### Formatting, option by option, against Foundation

| Operation | Ours | Decimal | Speedup |
|:----------|----------:|----------:|----------:|
| Default | 0 instr, 1394 ns | 0 instr, 4 allocs, 1570 ns | **∞** |
| Runtime currency | 0 instr, 1452 ns | 0 instr, 4 allocs, 1570 ns | **∞** |
| ISO code | 0 instr, 1448 ns | 0 instr, 4 allocs, 1568 ns | **∞** |
| Narrow symbol | 0 instr, 1428 ns | 0 instr, 4 allocs, 1554 ns | **∞** |
| Full name | 0 instr, 1 alloc, 1448 ns | 0 instr, 5 allocs, 1708 ns | **∞** |
| Sign, never | 0 instr, 1402 ns | 0 instr, 5 allocs, 1666 ns | **∞** |
| Sign, always | 0 instr, 1419 ns | 0 instr, 5 allocs, 1697 ns | **∞** |
| Sign, accounting | 0 instr, 1456 ns | 0 instr, 6 allocs, 1747 ns | **∞** |
| Grouping, never | 0 instr, 1464 ns | 0 instr, 4 allocs, 2230 ns | **∞** |
| Decimal separator, always | 0 instr, 1414 ns | 0 instr, 5 allocs, 1644 ns | **∞** |
| Precision, 2dp | 0 instr, 1456 ns | 0 instr, 4 allocs, 1564 ns | **∞** |
| Precision, 1dp | 0 instr, 1456 ns | 0 instr, 4 allocs, 1546 ns | **∞** |
| Precision and accounting | 0 instr, 1479 ns | 0 instr, 6 allocs, 1757 ns | **∞** |
| Every option | 0 instr, 1518 ns | 0 instr, 7 allocs, 1927 ns | **∞** |
| Rounding increment | 0 instr, 4 allocs, 1913 ns | n/a | n/a |
| Attributed | 0 instr, 35 allocs, 22000 ns | 0 instr, 36 allocs, 15000 ns | **∞** |
| Parse | 0 instr, 5 allocs, 2706 ns | 0 instr, 5 allocs, 1777 ns | **∞** |

### Typed currency against runtime currency

| Operation | Ours | Money | Speedup |
|:----------|----------:|----------:|----------:|
| Addition | 0 instr, 2 ns | 0 instr, 2 ns | **∞** |
| Subtraction | 0 instr, 2 ns | 0 instr, 2 ns | **∞** |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 3 ns | **∞** |
| Applying a rate | 0 instr, 5 ns | 0 instr, 4 ns | **∞** |
| Equality | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Hashing | 0 instr, 26 ns | 0 instr, 29 ns | **∞** |
| Construction, checked | 0 instr, 2 ns | 0 instr, 2 ns | **∞** |
| Description | 0 instr, 32 ns | 0 instr, 32 ns | **∞** |
| Parsing | 0 instr, 13 ns | 0 instr, 22 ns | **∞** |
| Proportion | 0 instr, 8 ns | 0 instr, 8 ns | **∞** |
| Split into 3 | 0 instr, 4 ns | 0 instr, 5 ns | **∞** |
| Split by weights | 0 instr, 4 allocs, 150 ns | 0 instr, 4 allocs, 157 ns | **∞** |
| Total of 10 | 0 instr, 5 ns | 0 instr, 7 ns | **∞** |
| Bytes encode | 0 instr, 16 ns | 0 instr, 18 ns | **∞** |
| Bytes decode | 0 instr, 9 ns | 0 instr, 11 ns | **∞** |
| Unrounded addition | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Unrounded subtraction | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Unrounded plus settled | 0 instr, 3 ns | 0 instr, 2 ns | **∞** |
| Unrounded minus settled | 0 instr, 3 ns | 0 instr, 4 ns | **∞** |
| Unrounded scaling by a rate | 0 instr, 12 ns | 0 instr, 13 ns | **∞** |
| Unrounded times an integer | 0 instr, 5 ns | 0 instr, 5 ns | **∞** |
| Unrounded divided | 0 instr, 10 ns | 0 instr, 8 ns | **∞** |
| Unrounded divided exactly | 0 instr, 9 ns | 0 instr, 10 ns | **∞** |
| Unrounded rounded | 0 instr, 7 ns | 0 instr, 8 ns | **∞** |
| Unrounded total of 10 | 0 instr, 6 ns | 0 instr, 7 ns | **∞** |
| Unrounded bytes decode | 0 instr, 24 ns | 0 instr, 25 ns | **∞** |

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
| Chained scaling, rounding each step | 0 instr, 34 ns |
| Rate from basis points | 0 instr, 3 ns |
| Rate from a decimal string | 0 instr, 57 ns |
| Exchange rate construction | 0 instr, 16 ns |
| Split into 3, runtime currency | 0 instr, 5 ns |
| Split, iterating the parts | 0 instr, 6 ns |
| Split into 1000, materialized | 0 instr, 1 alloc, 313 ns |
| Split by 10 weights | 0 instr, 4 allocs, 250 ns |
| Total of 10 | 0 instr, 5 ns |
| Total of 1000 | 0 instr, 309 ns |
| Currency code validation | 0 instr, 20 ns |
| Proportion | 0 instr, 8 ns |
| Proportion of large amounts | 0 instr, 11 ns |
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
Host 'runnervmmprz5' with 4 'x86_64' processors with 15 GB memory, running:
#22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026
```
## SwiftMoneyBenchmarks

### AnyCurrency storage for a custom field

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       117 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         9 |         9 |         9 |        11 |       117 |

### ClosedMoneyRange clamped, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         6 |       279 |

### ClosedMoneyRange construction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       284 |

### ClosedMoneyRange contains a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       287 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       287 |

### ClosedMoneyRange contains a half-open range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         5 |       285 |

### ClosedMoneyRange contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       284 |

### ClosedMoneyRange currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       562 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       562 |

### ClosedMoneyRange debug description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         9 |
| Time (wall clock) (ns) * |       117 |       117 |       117 |       118 |       119 |       119 |       119 |         9 |

### ClosedMoneyRange description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         9 |
| Time (wall clock) (ns) * |       111 |       111 |       111 |       112 |       113 |       113 |       113 |         9 |

### ClosedMoneyRange from a half-open range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       404 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       404 |

### ClosedMoneyRange from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       555 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       555 |

### ClosedMoneyRange from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       286 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       286 |

### ClosedMoneyRange is empty

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |     10000 |
| Time (wall clock) (ns) * |         0 |         0 |         0 |         0 |         0 |         0 |         0 |     10000 |

### ClosedMoneyRange lower bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       457 |

### ClosedMoneyRange overlaps a half-open range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       281 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       281 |

### ClosedMoneyRange overlaps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       279 |

### ClosedMoneyRange steps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       275 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         4 |       275 |

### ClosedMoneyRange upper bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       413 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         4 |         4 |       413 |

### ClosedRange from ClosedMoneyRange, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       453 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       453 |

### ClosedRange from a half-open range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       427 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       427 |

### ClosedRange from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       271 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         4 |       271 |

### ClosedRange of MoneyOf clamped

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       272 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         5 |       272 |

### ClosedRange of MoneyOf construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       277 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       277 |

### ClosedRange of MoneyOf contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       277 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       277 |

### ClosedRange of MoneyOf contains a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       277 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         6 |       277 |

### ClosedRange of MoneyOf contains a half-open range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       270 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         5 |         5 |       270 |

### ClosedRange of MoneyOf overlaps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       279 |

### ClosedRange of MoneyOf steps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       269 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         5 |         6 |       269 |

### Control JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         3 |
| Time (wall clock) (ns) * |       468 |       468 |       468 |       469 |       469 |       469 |       469 |         3 |

### Control JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         3 |
| Time (wall clock) (ns) * |       398 |       398 |       407 |       414 |       414 |       414 |       414 |         3 |

### Currency construction, custom

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       125 |
| Time (wall clock) (ns) * |         7 |         8 |         8 |         8 |         8 |         9 |         9 |       125 |

### Currency description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        65 |
| Time (wall clock) (ns) * |        14 |        15 |        15 |        16 |        16 |        16 |        16 |        65 |

### Currency equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       731 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         2 |       731 |

### CurrencyCode description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        55 |
| Time (wall clock) (ns) * |        17 |        18 |        18 |        18 |        19 |        20 |        20 |        55 |

### CurrencyCode equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       551 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       551 |

### CurrencyCode validation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        50 |
| Time (wall clock) (ns) * |        19 |        20 |        20 |        20 |        21 |        21 |        21 |        50 |

### CurrencyCode validation, eight characters

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        33 |        33 |        34 |        35 |        35 |        31 |

### CurrencyCode validation, lowercase

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        52 |
| Time (wall clock) (ns) * |        18 |        19 |        19 |        20 |        20 |        21 |        21 |        52 |

### CurrencyType storage for a field

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        33 |        33 |        34 |        34 |        34 |        31 |

### Decimal JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       549 |       549 |       549 |       549 |       549 |       549 |       549 |         2 |

### Decimal JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         2 |
| Time (wall clock) (ns) * |       548 |       548 |       548 |       551 |       551 |       551 |       551 |         2 |

### Decimal addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         8 |
| Time (wall clock) (ns) * |       130 |       132 |       133 |       133 |       134 |       134 |       134 |         8 |

### Decimal attributed, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        36 |        36 |        36 |        36 |        36 |        36 |        36 |         1 |
| Time (wall clock) (μs) * |        15 |        15 |        15 |        15 |        15 |        15 |        15 |         1 |

### Decimal chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1286 |      1286 |      1286 |      1286 |      1286 |      1286 |      1286 |         1 |

### Decimal comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        17 |
| Time (wall clock) (ns) * |        61 |        62 |        62 |        63 |        63 |        64 |        64 |        17 |

### Decimal description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       269 |       269 |       269 |       273 |       291 |       291 |       291 |         4 |

### Decimal divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1219 |      1219 |      1219 |      1219 |      1219 |      1219 |      1219 |         1 |

### Decimal format, ISO code, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1568 |      1568 |      1568 |      1568 |      1568 |      1568 |      1568 |         1 |

### Decimal format, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1570 |      1570 |      1570 |      1570 |      1570 |      1570 |      1570 |         1 |

### Decimal format, every option, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         1 |
| Time (wall clock) (ns) * |      1927 |      1927 |      1927 |      1927 |      1927 |      1927 |      1927 |         1 |

### Decimal format, full name, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1708 |      1708 |      1708 |      1708 |      1708 |      1708 |      1708 |         1 |

### Decimal format, grouping never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2230 |      2230 |      2230 |      2230 |      2230 |      2230 |      2230 |         1 |

### Decimal format, narrow, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1554 |      1554 |      1554 |      1554 |      1554 |      1554 |      1554 |         1 |

### Decimal format, precision 1dp and accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1757 |      1757 |      1757 |      1757 |      1757 |      1757 |      1757 |         1 |

### Decimal format, precision 1dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1546 |      1546 |      1546 |      1546 |      1546 |      1546 |      1546 |         1 |

### Decimal format, precision 2dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1564 |      1564 |      1564 |      1564 |      1564 |      1564 |      1564 |         1 |

### Decimal format, separator always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1644 |      1644 |      1644 |      1644 |      1644 |      1644 |      1644 |         1 |

### Decimal format, sign accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1747 |      1747 |      1747 |      1747 |      1747 |      1747 |      1747 |         1 |

### Decimal format, sign always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1697 |      1697 |      1697 |      1697 |      1697 |      1697 |      1697 |         1 |

### Decimal format, sign never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1666 |      1666 |      1666 |      1666 |      1666 |      1666 |      1666 |         1 |

### Decimal from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        83 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        13 |        14 |        14 |        83 |

### Decimal from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       212 |       212 |       215 |       218 |       234 |       234 |       234 |         5 |

### Decimal multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       262 |       262 |       263 |       265 |       265 |       265 |       265 |         4 |

### Decimal parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1777 |      1777 |      1777 |      1777 |      1777 |      1777 |      1777 |         1 |

### Decimal parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       211 |       211 |       212 |       212 |       213 |       213 |       213 |         5 |

### Decimal scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |       103 |       104 |       105 |       106 |       107 |       122 |       122 |        10 |

### Decimal scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      2444 |      2444 |      2444 |      2444 |      2444 |      2444 |      2444 |         1 |

### Decimal subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         8 |
| Time (wall clock) (ns) * |       128 |       129 |       129 |       130 |       131 |       131 |       131 |         8 |

### Double addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       557 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       557 |

### Double chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       302 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       302 |

### Double comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       548 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       548 |

### Double description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        27 |
| Time (wall clock) (ns) * |        37 |        37 |        38 |        38 |        38 |        39 |        39 |        27 |

### Double divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       420 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       420 |

### Double from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        40 |
| Time (wall clock) (ns) * |        25 |        25 |        26 |        26 |        26 |        27 |        27 |        40 |

### Double multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       405 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       405 |

### Double parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        37 |
| Time (wall clock) (ns) * |        26 |        27 |        27 |        28 |        29 |        29 |        29 |        37 |

### Double scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       552 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       552 |

### Double scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       370 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       370 |

### Double subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       556 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       556 |

### Engine format, accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         9 |
| Time (wall clock) (ns) * |       124 |       124 |       125 |       125 |       126 |       126 |       126 |         9 |

### Engine format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        11 |
| Time (wall clock) (ns) * |        92 |        92 |        94 |        95 |        95 |        95 |        95 |        11 |

### Engine format, grouped, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         8 |
| Time (wall clock) (ns) * |       128 |       128 |       129 |       130 |       136 |       136 |       136 |         8 |

### Engine format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |        99 |        99 |        99 |       100 |       101 |       113 |       113 |        10 |

### ExchangeRate JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2000 |      2000 |      2000 |      2000 |      2000 |      2000 |      2000 |         1 |

### ExchangeRate JSON decode, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2005 |      2005 |      2005 |      2005 |      2005 |      2005 |      2005 |         1 |

### ExchangeRate JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      1535 |      1535 |      1535 |      1535 |      1535 |      1535 |      1535 |         1 |

### ExchangeRate JSON encode, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      1499 |      1499 |      1499 |      1499 |      1499 |      1499 |      1499 |         1 |

### ExchangeRate applying a margin

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        69 |
| Time (wall clock) (ns) * |        13 |        14 |        15 |        15 |        15 |        16 |        16 |        69 |

### ExchangeRate construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        61 |
| Time (wall clock) (ns) * |        15 |        16 |        16 |        17 |        17 |        19 |        19 |        61 |

### ExchangeRate construction, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        55 |
| Time (wall clock) (ns) * |        17 |        18 |        18 |        19 |        19 |        20 |        20 |        55 |

### ExchangeRate crossed

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        84 |
| Time (wall clock) (ns) * |        11 |        12 |        12 |        12 |        12 |        13 |        13 |        84 |

### ExchangeRate description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        17 |
| Time (wall clock) (ns) * |        58 |        59 |        59 |        59 |        62 |        63 |        63 |        17 |

### ExchangeRate description, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        18 |
| Time (wall clock) (ns) * |        55 |        55 |        56 |        56 |        57 |        57 |        57 |        18 |

### ExchangeRate from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        17 |
| Time (wall clock) (ns) * |        60 |        61 |        61 |        62 |        63 |        63 |        63 |        17 |

### ExchangeRate from a decimal string, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        18 |
| Time (wall clock) (ns) * |        56 |        57 |        58 |        59 |        60 |        60 |        60 |        18 |

### ExchangeRate hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        30 |        30 |        31 |        31 |        34 |

### ExchangeRate inverted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        47 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        22 |        22 |        22 |        22 |        47 |

### FixedPoint JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       501 |       501 |       501 |       532 |       532 |       532 |       532 |         2 |

### FixedPoint JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         3 |
| Time (wall clock) (ns) * |       401 |       401 |       406 |       406 |       406 |       406 |       406 |         3 |

### FixedPoint addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       546 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       546 |

### FixedPoint chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        33 |
| Time (wall clock) (ns) * |        29 |        30 |        31 |        31 |        31 |        32 |        32 |        33 |

### FixedPoint comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       542 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       542 |

### FixedPoint description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        22 |
| Time (wall clock) (ns) * |        44 |        45 |        46 |        46 |        47 |        48 |        48 |        22 |

### FixedPoint division

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       114 |
| Time (wall clock) (ns) * |         8 |         9 |         9 |         9 |         9 |         9 |         9 |       114 |

### FixedPoint from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        56 |
| Time (wall clock) (ns) * |        17 |        17 |        18 |        18 |        19 |        21 |        21 |        56 |

### FixedPoint hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        38 |
| Time (wall clock) (ns) * |        26 |        26 |        26 |        27 |        27 |        28 |        28 |        38 |

### FixedPoint scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       129 |
| Time (wall clock) (ns) * |         7 |         8 |         8 |         8 |         8 |         8 |         8 |       129 |

### FixedPoint scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       100 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        11 |        11 |       100 |

### FixedPoint subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       557 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       557 |

### FractionLength construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       489 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       489 |

### Harness floor, a struct

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       616 |
| Time (wall clock) (ns) * |         1 |         1 |         2 |         2 |         2 |         2 |         2 |       616 |

### Harness floor, an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       816 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |       816 |

### ISO currency lookup

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       108 |
| Time (wall clock) (ns) * |         8 |         9 |         9 |        10 |        10 |        10 |        10 |       108 |

### Int addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       546 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       546 |

### Int chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       654 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         2 |         2 |         2 |       654 |

### Int comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       552 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       552 |

### Int description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        22 |
| Time (wall clock) (ns) * |        44 |        45 |        46 |        46 |        46 |        47 |        47 |        22 |

### Int from MoneyOf minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       461 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       461 |

### Int hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        39 |
| Time (wall clock) (ns) * |        26 |        26 |        26 |        26 |        27 |        27 |        27 |        39 |

### Int parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       174 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         6 |         6 |         7 |         8 |       174 |

### Int quotient and remainder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       486 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       486 |

### Int scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       532 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       532 |

### Int scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1587 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |      1587 |

### Int subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       551 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       551 |

### Int128 addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       538 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       538 |

### Int128 chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       135 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         8 |         8 |         8 |         8 |       135 |

### Int128 comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       552 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       552 |

### Int128 scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       324 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       324 |

### Int128 scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       428 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       428 |

### Int128 subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       552 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       552 |

### Margin construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       150 |
| Time (wall clock) (ns) * |         6 |         7 |         7 |         7 |         7 |         7 |         7 |       150 |

### Money JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       843 |       843 |       843 |       846 |       846 |       846 |       846 |         2 |

### Money JSON decode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        24 |        24 |        24 |        24 |        24 |        24 |        24 |         1 |
| Time (wall clock) (ns) * |      3419 |      3419 |      3419 |      3419 |      3419 |      3419 |      3419 |         1 |

### Money JSON decode, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1135 |      1135 |      1135 |      1135 |      1135 |      1135 |      1135 |         1 |

### Money JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         2 |
| Time (wall clock) (ns) * |       506 |       506 |       506 |       506 |       506 |       506 |       506 |         2 |

### Money JSON encode, major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       714 |       714 |       714 |       724 |       724 |       724 |       724 |         2 |

### Money JSON encode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      1999 |      1999 |      1999 |      1999 |      1999 |      1999 |      1999 |         1 |

### Money Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        40 |
| Time (wall clock) (ns) * |        25 |        25 |        25 |        26 |        26 |        27 |        27 |        40 |

### Money addition in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       481 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       481 |

### Money addition, separately built currencies

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       444 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       444 |

### Money addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       481 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       481 |

### Money applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       239 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         5 |         5 |         5 |       239 |

### Money array max of 128, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        62 |        63 |        63 |        64 |        69 |        75 |        75 |        16 |

### Money array max of 64, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        29 |        29 |        30 |        30 |        30 |        31 |        31 |        34 |

### Money array min of 128, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        62 |        62 |        63 |        63 |        64 |        64 |        64 |        16 |

### Money array min of 64, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        30 |        30 |        33 |        33 |        34 |

### Money bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        92 |
| Time (wall clock) (ns) * |        10 |        11 |        11 |        11 |        11 |        12 |        12 |        92 |

### Money bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        57 |
| Time (wall clock) (ns) * |        17 |        18 |        18 |        18 |        18 |        19 |        19 |        57 |

### Money clamped to a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       403 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         4 |       403 |

### Money clamped to a lower bound, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       376 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       376 |

### Money clamped to an upper bound, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       383 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       383 |

### Money description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        32 |
| Time (wall clock) (ns) * |        31 |        31 |        32 |        32 |        33 |        33 |        33 |        32 |

### Money encode, no coder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         9 |
| Time (wall clock) (ns) * |       114 |       115 |       115 |       116 |       119 |       119 |       119 |         9 |

### Money encode, no coder, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         3 |
| Time (wall clock) (ns) * |       397 |       397 |       397 |       402 |       402 |       402 |       402 |         3 |

### Money equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       279 |

### Money format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1452 |      1452 |      1452 |      1452 |      1452 |      1452 |      1452 |         1 |

### Money from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       518 |       518 |       518 |       542 |       542 |       542 |       542 |         2 |

### Money from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       535 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       535 |

### Money hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        30 |        30 |        30 |        30 |        34 |

### Money init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       492 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       492 |

### Money init major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       322 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         4 |         4 |         4 |       322 |

### Money init major units, Int64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       321 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         4 |         4 |         4 |       321 |

### Money init major units, UInt32

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       299 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         4 |         4 |         4 |         4 |       299 |

### Money is less than, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       511 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       511 |

### Money is multiple, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       488 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       488 |

### Money max of five, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        89 |
| Time (wall clock) (ns) * |        10 |        11 |        11 |        11 |        12 |        12 |        12 |        89 |

### Money max of three, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       190 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       190 |

### Money max, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       275 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         4 |       275 |

### Money min of five, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        85 |
| Time (wall clock) (ns) * |        10 |        11 |        12 |        12 |        13 |        13 |        13 |        85 |

### Money min of three, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       187 |

### Money min, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       275 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         6 |       275 |

### Money parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2681 |      2681 |      2681 |      2681 |      2681 |      2681 |      2681 |         1 |

### Money parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        46 |
| Time (wall clock) (ns) * |        20 |        21 |        22 |        22 |        23 |        24 |        24 |        46 |

### Money parsing, caller's currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        61 |
| Time (wall clock) (ns) * |        15 |        16 |        16 |        17 |        17 |        17 |        17 |        61 |

### Money parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        47 |
| Time (wall clock) (ns) * |        19 |        21 |        21 |        22 |        22 |        23 |        23 |        47 |

### Money proportion, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       117 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         9 |         9 |        10 |        10 |       117 |

### Money scalar multiplication, amount times integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       380 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       380 |

### Money scalar multiplication, integer times amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       380 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       380 |

### Money split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         7 |
| Time (wall clock) (ns) * |       155 |       156 |       157 |       158 |       159 |       159 |       159 |         7 |

### Money split equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       278 |

### Money split hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        26 |
| Time (wall clock) (ns) * |        38 |        39 |        39 |        39 |        40 |        40 |        40 |        26 |

### Money split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         3 |
| Time (wall clock) (ns) * |       376 |       376 |       378 |       381 |       381 |       381 |       381 |         3 |

### Money split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       190 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       190 |

### Money subtraction in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       556 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       556 |

### Money subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       447 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       447 |

### Money total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       140 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         8 |       140 |

### Money total of 1000, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       600 |       600 |       600 |       601 |       601 |       601 |       601 |         2 |

### Money unrounded addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       274 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         5 |         6 |       274 |

### Money unrounded applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        76 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        14 |        14 |        14 |        76 |

### Money unrounded divided by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       116 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         9 |         9 |         9 |         9 |       116 |

### Money unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       103 |
| Time (wall clock) (ns) * |         9 |         9 |        10 |        10 |        10 |        11 |        12 |       103 |

### Money unrounded minus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       270 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         4 |       270 |

### Money unrounded plus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       445 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       445 |

### Money unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       118 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         9 |         9 |         9 |         9 |       118 |

### Money unrounded scaling by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        75 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        14 |        14 |        14 |        14 |        75 |

### Money unrounded scaling by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       202 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       202 |

### Money unrounded subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       282 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       282 |

### Money unrounded total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       133 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         8 |         8 |         9 |         9 |       133 |

### Money.Steps bounds

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       552 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       552 |

### Money.Steps contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       180 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         6 |         6 |         6 |         6 |       180 |

### Money.Steps firstIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       186 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       186 |

### Money.Steps from bounds and step, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       185 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         6 |         6 |         6 |         7 |       185 |

### Money.Steps from typed steps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       521 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       521 |

### Money.Steps index for an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       163 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       163 |

### Money.Steps index for an amount, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       125 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         9 |         9 |       125 |

### Money.Steps index for an amount, ties away from zero, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       136 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         8 |         8 |         8 |       136 |

### Money.Steps index offset by, limited by

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       392 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       392 |

### Money.Steps lastIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       189 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       189 |

### Money.Steps subscript

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       345 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       345 |

### Money.Steps walk, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       116 |
| Time (wall clock) (ns) * |         8 |         8 |         9 |         9 |         9 |         9 |         9 |       116 |

### Money.Steps.Selection amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       366 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       366 |

### Money.Steps.Selection from a typed selection

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       473 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       473 |

### Money.Steps.Selection from an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       148 |
| Time (wall clock) (ns) * |         6 |         7 |         7 |         7 |         7 |         7 |         9 |       148 |

### Money.Steps.Selection from an amount, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       124 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         9 |        10 |       124 |

### Money.Steps.Selection from an amount, ties away from zero, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       129 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       129 |

### Money.Steps.Selection selecting an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       158 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         7 |         7 |         7 |       158 |

### Money.Steps.Selection selecting an amount, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       122 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         9 |         9 |         9 |       122 |

### Money.Steps.Selection selecting an amount, ties away from zero, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       130 |
| Time (wall clock) (ns) * |         7 |         8 |         8 |         8 |         8 |         8 |         8 |       130 |

### Money.Steps.Selection selecting an index

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       357 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       357 |

### Money.Stride from a typed stride

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       538 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       538 |

### Money.Stride init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       346 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       346 |

### Money.Stride major unit of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       310 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         4 |         4 |       310 |

### Money.Stride major unit of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       258 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       258 |

### Money.Stride major units of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       292 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       292 |

### Money.Stride major units of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       290 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       290 |

### Money.Stride minor unit of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       459 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       459 |

### Money.Stride minor unit of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       540 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       540 |

### Money.Stride minor units of a currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       542 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       542 |

### Money.Stride minor units of an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       551 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         4 |       551 |

### MoneyCodingFormat custom fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         4 |
| Time (wall clock) (ns) * |       324 |       324 |       325 |       327 |       327 |       327 |       327 |         4 |

### MoneyLocalization moneyFormat, EN_gb

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       867 |       867 |       867 |       867 |       867 |       867 |       867 |         2 |

### MoneyLocalization moneyFormat, ISO code, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       825 |       826 |       826 |       828 |       828 |       828 |       828 |         2 |

### MoneyLocalization moneyFormat, en-Latn-US

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1992 |      1992 |      1992 |      1992 |      1992 |      1992 |      1992 |         1 |

### MoneyLocalization moneyFormat, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       821 |       822 |       822 |       822 |       822 |       822 |       822 |         2 |

### MoneyLocalization moneyFormat, en_US

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1201 |      1201 |      1201 |      1201 |      1201 |      1201 |      1201 |         1 |

### MoneyLocalization moneyFormat, en_US_POSIX

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1535 |      1535 |      1535 |      1535 |      1535 |      1535 |      1535 |         1 |

### MoneyLocalization moneyFormat, sr-Latn_RS

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1334 |      1334 |      1334 |      1334 |      1334 |      1334 |      1334 |         1 |

### MoneyLocalization moneyFormat, zh_TW

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       849 |       849 |       849 |       854 |       854 |       854 |       854 |         2 |

### MoneyOf JSON decode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      1204 |      1204 |      1204 |      1204 |      1204 |      1204 |      1204 |         1 |

### MoneyOf JSON encode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       687 |       687 |       687 |       688 |       688 |       688 |       688 |         2 |

### MoneyOf Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        23 |        24 |        24 |        25 |        25 |        25 |        25 |        41 |

### MoneyOf Unrounded bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        44 |
| Time (wall clock) (ns) * |        22 |        23 |        23 |        23 |        24 |        24 |        24 |        44 |

### MoneyOf addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       544 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       544 |

### MoneyOf addition in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       541 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       541 |

### MoneyOf addition near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      2289 |
| Time (wall clock) (ns) * |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      2289 |

### MoneyOf applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       214 |
| Time (wall clock) (ns) * |         4 |         4 |         5 |         5 |         5 |         6 |         6 |       214 |

### MoneyOf array max of 128

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |       102 |       103 |       103 |       104 |       104 |       104 |       104 |        10 |

### MoneyOf array max of 64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        20 |
| Time (wall clock) (ns) * |        50 |        50 |        50 |        51 |        51 |        52 |        52 |        20 |

### MoneyOf array min of 128

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |       102 |       103 |       104 |       105 |       105 |       108 |       108 |        10 |

### MoneyOf array min of 64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        20 |
| Time (wall clock) (ns) * |        50 |        50 |        51 |        52 |        52 |        52 |        52 |        20 |

### MoneyOf attributed, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        35 |        35 |        35 |        35 |        35 |        35 |        35 |         1 |
| Time (wall clock) (μs) * |        22 |        22 |        22 |        22 |        22 |        22 |        22 |         1 |

### MoneyOf bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       112 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |        10 |       112 |

### MoneyOf bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        61 |
| Time (wall clock) (ns) * |        15 |        16 |        16 |        17 |        17 |        19 |        19 |        61 |

### MoneyOf bytes encode, extremes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        63 |
| Time (wall clock) (ns) * |        15 |        16 |        16 |        17 |        17 |        17 |        17 |        63 |

### MoneyOf chain, rounding each step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        30 |
| Time (wall clock) (ns) * |        34 |        34 |        34 |        35 |        35 |        36 |        36 |        30 |

### MoneyOf clamped to a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       409 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         3 |         3 |       409 |

### MoneyOf clamped to a lower bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       549 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       549 |

### MoneyOf clamped to an upper bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       404 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       404 |

### MoneyOf comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       541 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       541 |

### MoneyOf converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       274 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         5 |       274 |

### MoneyOf currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       651 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       651 |

### MoneyOf description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        31 |        32 |        32 |        33 |        33 |        33 |        33 |        31 |

### MoneyOf description, large negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         9 |
| Time (wall clock) (ns) * |       120 |       120 |       121 |       123 |       134 |       134 |       134 |         9 |

### MoneyOf equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       283 |

### MoneyOf format, ISO code, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1448 |      1448 |      1448 |      1448 |      1448 |      1448 |      1448 |         1 |

### MoneyOf format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1394 |      1394 |      1394 |      1394 |      1394 |      1394 |      1394 |         1 |

### MoneyOf format, every option, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1518 |      1518 |      1518 |      1518 |      1518 |      1518 |      1518 |         1 |

### MoneyOf format, full name, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
| Time (wall clock) (ns) * |      1448 |      1448 |      1448 |      1448 |      1448 |      1448 |      1448 |         1 |

### MoneyOf format, grouping never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1464 |      1464 |      1464 |      1464 |      1464 |      1464 |      1464 |         1 |

### MoneyOf format, increment, en_GB [ICU fallback]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      1913 |      1913 |      1913 |      1913 |      1913 |      1913 |      1913 |         1 |

### MoneyOf format, narrow, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1428 |      1428 |      1428 |      1428 |      1428 |      1428 |      1428 |         1 |

### MoneyOf format, precision 1dp and accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1479 |      1479 |      1479 |      1479 |      1479 |      1479 |      1479 |         1 |

### MoneyOf format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1456 |      1456 |      1456 |      1456 |      1456 |      1456 |      1456 |         1 |

### MoneyOf format, precision 2dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1456 |      1456 |      1456 |      1456 |      1456 |      1456 |      1456 |         1 |

### MoneyOf format, separator always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1414 |      1414 |      1414 |      1414 |      1414 |      1414 |      1414 |         1 |

### MoneyOf format, sign accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1456 |      1456 |      1456 |      1456 |      1456 |      1456 |      1456 |         1 |

### MoneyOf format, sign always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1419 |      1419 |      1419 |      1419 |      1419 |      1419 |      1419 |         1 |

### MoneyOf format, sign never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1402 |      1402 |      1402 |      1402 |      1402 |      1402 |      1402 |         1 |

### MoneyOf from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       512 |       512 |       512 |       512 |       512 |       512 |       512 |         2 |

### MoneyOf from Money, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       383 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       383 |

### MoneyOf from a negative Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       553 |       553 |       553 |       557 |       557 |       557 |       557 |         2 |

### MoneyOf hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        39 |
| Time (wall clock) (ns) * |        25 |        26 |        26 |        26 |        26 |        26 |        26 |        39 |

### MoneyOf init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       494 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       494 |

### MoneyOf init major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       319 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         4 |         4 |       319 |

### MoneyOf init major units, Int64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       326 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         4 |         4 |       326 |

### MoneyOf init major units, UInt32

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       311 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         4 |         4 |       311 |

### MoneyOf is multiple

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       557 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       557 |

### MoneyOf is negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       562 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       562 |

### MoneyOf is positive

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       562 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       562 |

### MoneyOf is zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       563 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       563 |

### MoneyOf magnitude

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       374 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       374 |

### MoneyOf max

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       284 |

### MoneyOf max of five

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        39 |
| Time (wall clock) (ns) * |        26 |        26 |        26 |        26 |        26 |        26 |        26 |        39 |

### MoneyOf max of three

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       192 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       192 |

### MoneyOf min

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       285 |

### MoneyOf min of five

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        39 |
| Time (wall clock) (ns) * |        26 |        26 |        26 |        26 |        26 |        27 |        27 |        39 |

### MoneyOf min of three

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       191 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       191 |

### MoneyOf negation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       395 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       395 |

### MoneyOf parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2706 |      2706 |      2706 |      2706 |      2706 |      2706 |      2706 |         1 |

### MoneyOf parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        79 |
| Time (wall clock) (ns) * |        12 |        12 |        13 |        13 |        13 |        14 |        14 |        79 |

### MoneyOf parsing a large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        33 |
| Time (wall clock) (ns) * |        31 |        31 |        31 |        31 |        31 |        33 |        33 |        33 |

### MoneyOf parsing a negative amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        89 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        12 |        13 |        13 |        89 |

### MoneyOf parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        74 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        14 |        14 |        15 |        15 |        74 |

### MoneyOf proportion

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       124 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         9 |        10 |        10 |       124 |

### MoneyOf proportion of large amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        94 |
| Time (wall clock) (ns) * |        10 |        11 |        11 |        11 |        11 |        11 |        11 |        94 |

### MoneyOf scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       540 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       540 |

### MoneyOf scalar multiplication in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       455 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       455 |

### MoneyOf scalar multiplication near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### MoneyOf scalar multiplication, Int32 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       325 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       325 |

### MoneyOf scalar multiplication, Int64 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       543 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       543 |

### MoneyOf scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       118 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         9 |         9 |         9 |       118 |

### MoneyOf scaled and rounded, large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       102 |
| Time (wall clock) (ns) * |         9 |        10 |        10 |        10 |        10 |        10 |        11 |       102 |

### MoneyOf split by 10 weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         5 |
| Time (wall clock) (ns) * |       249 |       249 |       250 |       250 |       250 |       250 |       250 |         5 |

### MoneyOf split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         7 |
| Time (wall clock) (ns) * |       149 |       149 |       150 |       150 |       151 |       151 |       151 |         7 |

### MoneyOf split by weights that divide exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |        10 |
| Time (wall clock) (ns) * |       102 |       103 |       103 |       104 |       104 |       104 |       104 |        10 |

### MoneyOf split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         4 |
| Time (wall clock) (ns) * |       312 |       312 |       313 |       314 |       315 |       315 |       315 |         4 |

### MoneyOf split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       222 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         5 |         5 |         5 |         5 |       222 |

### MoneyOf split, iterating the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       154 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         7 |         7 |         7 |         7 |       154 |

### MoneyOf subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       564 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       564 |

### MoneyOf total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       181 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         6 |         6 |         6 |         7 |       181 |

### MoneyOf total of 1000

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       308 |       308 |       309 |       310 |       310 |       310 |       310 |         4 |

### MoneyOf unrounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       460 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       460 |

### MoneyOf unrounded addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       285 |

### MoneyOf unrounded chain

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        21 |
| Time (wall clock) (ns) * |        49 |        49 |        49 |        49 |        50 |        57 |        57 |        21 |

### MoneyOf unrounded converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        75 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        14 |        14 |        14 |        75 |

### MoneyOf unrounded divided

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        98 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        11 |        11 |        98 |

### MoneyOf unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       109 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        10 |       109 |

### MoneyOf unrounded from major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        17 |
| Time (wall clock) (ns) * |        60 |        61 |        62 |        62 |        63 |        64 |        64 |        17 |

### MoneyOf unrounded from minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       531 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       531 |

### MoneyOf unrounded minus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       283 |

### MoneyOf unrounded plus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       281 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       281 |

### MoneyOf unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       141 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         8 |         8 |         8 |       141 |

### MoneyOf unrounded scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        82 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        13 |        13 |        13 |        82 |

### MoneyOf unrounded subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       277 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       277 |

### MoneyOf unrounded times an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       203 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         7 |       203 |

### MoneyOf unrounded total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       167 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       167 |

### MoneyOf unroundedBytes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        45 |
| Time (wall clock) (ns) * |        22 |        22 |        22 |        23 |        23 |        24 |        24 |        45 |

### MoneyOf.Steps bounds

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       534 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       534 |

### MoneyOf.Steps contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       186 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         6 |         6 |         6 |         6 |       186 |

### MoneyOf.Steps firstIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       189 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       189 |

### MoneyOf.Steps from bounds and step, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       189 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       189 |

### MoneyOf.Steps from runtime steps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       328 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       328 |

### MoneyOf.Steps index for an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       134 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         8 |         8 |         8 |         8 |       134 |

### MoneyOf.Steps index for an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       167 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         7 |       167 |

### MoneyOf.Steps index for an amount, ties away from zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       145 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         7 |         8 |       145 |

### MoneyOf.Steps index offset by, limited by

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       392 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       392 |

### MoneyOf.Steps lastIndex of

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       186 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         7 |         7 |       186 |

### MoneyOf.Steps subscript

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       365 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       365 |

### MoneyOf.Steps walk, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       121 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         9 |         9 |       121 |

### MoneyOf.Steps.Selection amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       432 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       432 |

### MoneyOf.Steps.Selection from a runtime selection, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       382 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       382 |

### MoneyOf.Steps.Selection from an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       126 |
| Time (wall clock) (ns) * |         7 |         8 |         8 |         8 |         8 |         9 |        10 |       126 |

### MoneyOf.Steps.Selection from an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       163 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       163 |

### MoneyOf.Steps.Selection from an amount, ties away from zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       135 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         8 |         8 |         8 |       135 |

### MoneyOf.Steps.Selection selecting an amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       129 |
| Time (wall clock) (ns) * |         7 |         8 |         8 |         8 |         8 |         8 |         8 |       129 |

### MoneyOf.Steps.Selection selecting an amount, rounding down, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       166 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         7 |       166 |

### MoneyOf.Steps.Selection selecting an amount, ties away from zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       134 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         8 |         9 |        11 |       134 |

### MoneyOf.Steps.Selection selecting an index

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       389 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       389 |

### MoneyOf.Stride from a runtime stride, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       384 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       384 |

### MoneyOf.Stride init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       462 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       462 |

### MoneyOf.Stride major unit

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       282 |
| Time (wall clock) (ns) * |         3 |         3 |         4 |         4 |         4 |         4 |         4 |       282 |

### MoneyOf.Stride major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       318 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         4 |       318 |

### MoneyOf.Stride minor unit

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       593 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       593 |

### MoneyOf.Stride minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       489 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       489 |

### MoneyRange clamped, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       282 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       282 |

### MoneyRange construction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       273 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       273 |

### MoneyRange contains a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       283 |

### MoneyRange contains a half-open range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       285 |

### MoneyRange contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       284 |

### MoneyRange currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       560 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       560 |

### MoneyRange debug description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         9 |
| Time (wall clock) (ns) * |       116 |       117 |       118 |       118 |       119 |       119 |       119 |         9 |

### MoneyRange description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         9 |
| Time (wall clock) (ns) * |       111 |       112 |       113 |       113 |       124 |       124 |       124 |         9 |

### MoneyRange from a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       381 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       381 |

### MoneyRange from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       546 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       546 |

### MoneyRange from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       283 |

### MoneyRange is empty

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       553 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       553 |

### MoneyRange lower bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       456 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       456 |

### MoneyRange overlaps a closed range, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       283 |

### MoneyRange overlaps, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       283 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       283 |

### MoneyRange upper bound

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       443 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         3 |         3 |       443 |

### NSDecimalNumber addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         6 |
| Time (wall clock) (ns) * |       167 |       168 |       168 |       170 |       171 |       171 |       171 |         6 |

### NSDecimalNumber comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        63 |        63 |        64 |        64 |        65 |        65 |        65 |        16 |

### NSDecimalNumber multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         3 |
| Time (wall clock) (ns) * |       347 |       347 |       348 |       353 |       353 |       353 |       353 |         3 |

### NSDecimalNumber parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         5 |
| Time (wall clock) (ns) * |       233 |       234 |       235 |       235 |       236 |       236 |       236 |         5 |

### PartCount construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       444 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       444 |

### PartialMoneyRangeFrom construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       557 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       557 |

### PartialMoneyRangeFrom contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       284 |

### PartialMoneyRangeFrom currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       544 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       544 |

### PartialMoneyRangeFrom from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       232 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         5 |         5 |         5 |       232 |

### PartialMoneyRangeThrough construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       561 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       561 |

### PartialMoneyRangeThrough contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       284 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       284 |

### PartialMoneyRangeThrough currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       549 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       549 |

### PartialMoneyRangeThrough from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       210 |
| Time (wall clock) (ns) * |         4 |         4 |         5 |         5 |         5 |         5 |         5 |       210 |

### PartialMoneyRangeUpTo construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       549 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       549 |

### PartialMoneyRangeUpTo contains, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       279 |

### PartialMoneyRangeUpTo currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       550 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       550 |

### PartialMoneyRangeUpTo from a typed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       206 |
| Time (wall clock) (ns) * |         4 |         5 |         5 |         5 |         5 |         6 |         6 |       206 |

### PartialRangeFrom from PartialMoneyRangeFrom, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       154 |
| Time (wall clock) (ns) * |         5 |         6 |         7 |         7 |         7 |         7 |         7 |       154 |

### PartialRangeThrough from PartialMoneyRangeThrough, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       160 |
| Time (wall clock) (ns) * |         5 |         6 |         6 |         6 |         6 |         7 |         7 |       160 |

### PartialRangeUpTo from PartialMoneyRangeUpTo, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       194 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       194 |

### PartialRangeUpTo of MoneyOf construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       410 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         3 |         3 |       410 |

### PartialRangeUpTo of MoneyOf contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       280 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       280 |

### Range from MoneyRange, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       467 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       467 |

### Range from a closed range

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       366 |
| Time (wall clock) (ns) * |         2 |         3 |         3 |         3 |         3 |         3 |         3 |       366 |

### Range from checked bounds, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       279 |

### Range of MoneyOf construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       277 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         4 |         4 |       277 |

### Range of MoneyOf contains

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       273 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         4 |         4 |         5 |         5 |       273 |

### Rate equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       686 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         2 |         2 |         2 |       686 |

### Rate from a Double

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       159 |       160 |       160 |       162 |       163 |       163 |       163 |         7 |

### Rate from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        18 |
| Time (wall clock) (ns) * |        56 |        56 |        57 |        58 |        60 |        61 |        61 |        18 |

### Rate from a fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       145 |       146 |       146 |       147 |       149 |       149 |       149 |         7 |

### Rate from a large decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         9 |
| Time (wall clock) (ns) * |       120 |       121 |       122 |       123 |       125 |       125 |       125 |         9 |

### Rate from a negative decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        60 |        62 |        63 |        63 |        64 |        64 |        64 |        16 |

### Rate from a negative fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       166 |       167 |       167 |       169 |       170 |       170 |       170 |         6 |

### Rate from a percent string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        88 |        89 |        90 |        91 |        94 |       104 |       104 |        12 |

### Rate from a string literal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        20 |
| Time (wall clock) (ns) * |        50 |        50 |        51 |        51 |        56 |        59 |        59 |        20 |

### Rate from basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       345 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       345 |

### Rate from percent

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       329 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         5 |       329 |

### Rate to basis points, rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       109 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |        10 |        11 |        11 |       109 |

### Rate to whole basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       135 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         8 |         8 |         8 |         8 |       135 |

### Split counting the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       403 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       403 |

### Split equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       282 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         4 |         4 |         4 |       282 |

### Split hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        30 |
| Time (wall clock) (ns) * |        34 |        34 |        34 |        34 |        35 |        35 |        35 |        30 |

### UnevenSplit smaller amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       532 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       532 |

### UnitPrice total for a fractional quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        92 |
| Time (wall clock) (ns) * |        10 |        11 |        11 |        11 |        11 |        12 |        12 |        92 |

### UnitPrice total for a whole quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       239 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       239 |

### UnitScale construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       214 |
| Time (wall clock) (ns) * |         4 |         5 |         5 |         5 |         5 |         5 |         5 |       214 |

### UnitScale from decimal places

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       501 |
| Time (wall clock) (ns) * |         1 |         2 |         2 |         2 |         2 |         2 |         2 |       501 |

### Weight construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       494 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       494 |

### WeightedSplit amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        32 |
| Time (wall clock) (ns) * |        31 |        32 |        32 |        32 |        32 |        32 |        32 |        32 |

### WeightedSplit count

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       541 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       541 |

### WeightedSplit hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        22 |
| Time (wall clock) (ns) * |        46 |        46 |        46 |        46 |        47 |        47 |        47 |        22 |

### WeightedSplit weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        32 |
| Time (wall clock) (ns) * |        31 |        31 |        31 |        32 |        32 |        33 |        33 |        32 |

### Weights construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        47 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        21 |        22 |        22 |        22 |        47 |

### stride through Int64, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       153 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         7 |         7 |         7 |         7 |       153 |

### stride through Money contains, between steps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       183 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       183 |

### stride through Money contains, in another currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       285 |

### stride through Money contains, on a step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       183 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       183 |

### stride through Money contains, past the end

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       280 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       280 |

### stride through Money, 10000 amounts, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        13 |        13 |        13 |        13 |        13 |        18 |        38 |     10000 |

### stride through Money, 20000 amounts, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        25 |        26 |        26 |        26 |        26 |        31 |        47 |     10000 |

### stride through Money, £250 by £25, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       176 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       176 |

### stride through MoneyOf contains, between steps

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       190 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       190 |

### stride through MoneyOf contains, on a step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         7 |         7 |       187 |

### stride through MoneyOf contains, past the end

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       280 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       280 |

### stride through MoneyOf underestimatedCount, Int.max

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       519 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       519 |

### stride through MoneyOf underestimatedCount, eleven amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       514 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       514 |

### stride through MoneyOf, 10000 amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        11 |        12 |        12 |        12 |        13 |        17 |        53 |     10000 |

### stride through MoneyOf, 20000 amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        23 |        23 |        23 |        23 |        25 |        28 |        62 |     10000 |

### stride through MoneyOf, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       182 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       182 |

### stride to Money contains, on a step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       182 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       182 |

### stride to Money, 10000 amounts, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        13 |        13 |        13 |        13 |        14 |        18 |        63 |     10000 |

### stride to Money, 20000 amounts, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        26 |        26 |        26 |        26 |        27 |        31 |        93 |     10000 |

### stride to Money, £250 by £25, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       174 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       174 |

### stride to MoneyOf contains, on a step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       190 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         6 |       190 |

### stride to MoneyOf contains, past the end

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       280 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       280 |

### stride to MoneyOf underestimatedCount, ten amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       519 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       519 |

### stride to MoneyOf, 10000 amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        12 |        12 |        12 |        12 |        12 |        17 |        46 |     10000 |

### stride to MoneyOf, 20000 amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        16 |        16 |        16 |        16 |        16 |        16 |        18 |     10000 |
| Time (wall clock) (μs) * |        23 |        23 |        23 |        23 |        25 |        28 |        52 |     10000 |

### stride to MoneyOf, £250 by £25

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       182 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         6 |         6 |         6 |       182 |


<!-- BENCHMARK-END -->

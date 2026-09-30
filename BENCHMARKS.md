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
| Addition | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 173 ns |
| Subtraction | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 168 ns |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 152 ns |
| Scale and round | 0 instr, 11 ns | 0 instr, 1 ns | 0 instr, 4 ns | 0 instr, 2883 ns |
| Comparison | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 78 ns |
| Split into 3 | 0 instr, 8 ns | 0 instr, 3 ns | 0 instr, 4 ns | 0 instr, 1403 ns |
| Chained scaling | 0 instr, 65 ns | 0 instr, 2 ns | 0 instr, 5 ns | 0 instr, 1477 ns |

### Formatting, option by option, against Foundation

| Operation | Ours | Decimal | Speedup |
|:----------|----------:|----------:|----------:|
| Default | 0 instr, 1645 ns | 0 instr, 4 allocs, 2185 ns | **∞** |
| Runtime currency | 0 instr, 1667 ns | 0 instr, 4 allocs, 2185 ns | **∞** |
| ISO code | 0 instr, 1731 ns | 0 instr, 4 allocs, 2234 ns | **∞** |
| Narrow symbol | 0 instr, 1690 ns | 0 instr, 4 allocs, 2196 ns | **∞** |
| Full name | 0 instr, 1 alloc, 1954 ns | 0 instr, 5 allocs, 2390 ns | **∞** |
| Sign, never | 0 instr, 1664 ns | 0 instr, 5 allocs, 2351 ns | **∞** |
| Sign, always | 0 instr, 1664 ns | 0 instr, 5 allocs, 2356 ns | **∞** |
| Sign, accounting | 0 instr, 1686 ns | 0 instr, 6 allocs, 2441 ns | **∞** |
| Grouping, never | 0 instr, 1657 ns | 0 instr, 4 allocs, 2916 ns | **∞** |
| Decimal separator, always | 0 instr, 1629 ns | 0 instr, 5 allocs, 2273 ns | **∞** |
| Precision, 2dp | 0 instr, 1699 ns | 0 instr, 4 allocs, 2183 ns | **∞** |
| Precision, 1dp | 0 instr, 1692 ns | 0 instr, 4 allocs, 2176 ns | **∞** |
| Precision and accounting | 0 instr, 1748 ns | 0 instr, 6 allocs, 2389 ns | **∞** |
| Every option | 0 instr, 1824 ns | 0 instr, 7 allocs, 2613 ns | **∞** |
| Rounding increment | 0 instr, 4 allocs, 2782 ns | n/a | n/a |
| Attributed | 0 instr, 35 allocs, 32000 ns | 0 instr, 36 allocs, 23000 ns | **∞** |
| Parse | 0 instr, 5 allocs, 3950 ns | 0 instr, 5 allocs, 2525 ns | **∞** |

### Typed currency against runtime currency

| Operation | Ours | Money | Speedup |
|:----------|----------:|----------:|----------:|
| Addition | 0 instr, 2 ns | 0 instr, 3 ns | **∞** |
| Subtraction | 0 instr, 2 ns | 0 instr, 3 ns | **∞** |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 3 ns | **∞** |
| Applying a rate | 0 instr, 6 ns | 0 instr, 6 ns | **∞** |
| Equality | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Hashing | 0 instr, 29 ns | 0 instr, 33 ns | **∞** |
| Construction, checked | 0 instr, 3 ns | 0 instr, 3 ns | **∞** |
| Description | 0 instr, 38 ns | 0 instr, 36 ns | **∞** |
| Parsing | 0 instr, 16 ns | 0 instr, 26 ns | **∞** |
| Proportion | 0 instr, 11 ns | 0 instr, 12 ns | **∞** |
| Split into 3 | 0 instr, 8 ns | 0 instr, 9 ns | **∞** |
| Split by weights | 0 instr, 4 allocs, 186 ns | 0 instr, 4 allocs, 183 ns | **∞** |
| Total of 10 | 0 instr, 6 ns | 0 instr, 7 ns | **∞** |
| Bytes encode | 0 instr, 21 ns | 0 instr, 17 ns | **∞** |
| Bytes decode | 0 instr, 16 ns | 0 instr, 18 ns | **∞** |
| Unrounded addition | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded subtraction | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded plus settled | 0 instr, 4 ns | 0 instr, 3 ns | **∞** |
| Unrounded minus settled | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded scaling by a rate | 0 instr, 20 ns | 0 instr, 21 ns | **∞** |
| Unrounded times an integer | 0 instr, 6 ns | 0 instr, 6 ns | **∞** |
| Unrounded divided | 0 instr, 11 ns | 0 instr, 11 ns | **∞** |
| Unrounded divided exactly | 0 instr, 11 ns | 0 instr, 11 ns | **∞** |
| Unrounded rounded | 0 instr, 9 ns | 0 instr, 9 ns | **∞** |
| Unrounded total of 10 | 0 instr, 6 ns | 0 instr, 8 ns | **∞** |
| Unrounded bytes decode | 0 instr, 32 ns | 0 instr, 38 ns | **∞** |

### What the measurement itself costs

| Operation | Ours |
|:----------|----------:|
| Handing an integer to the harness | 0 instr, 2 ns |
| Handing a struct to the harness | 0 instr, 3 ns |

### SwiftMoney's own operations

| Operation | Ours |
|:----------|----------:|
| Addition, throwing | 0 instr, 3 ns |
| Widening to unrounded | 0 instr, 3 ns |
| Scale, leaving it unrounded | 0 instr, 20 ns |
| Unrounded addition | 0 instr, 4 ns |
| Chained scaling, rounding each step | 0 instr, 35 ns |
| Rate from basis points | 0 instr, 4 ns |
| Rate from a decimal string | 0 instr, 62 ns |
| Exchange rate construction | 0 instr, 24 ns |
| Split into 3, runtime currency | 0 instr, 9 ns |
| Split, iterating the parts | 0 instr, 9 ns |
| Split into 1000, materialized | 0 instr, 1 alloc, 648 ns |
| Split by 10 weights | 0 instr, 4 allocs, 308 ns |
| Total of 10 | 0 instr, 6 ns |
| Total of 1000 | 0 instr, 320 ns |
| Currency code validation | 0 instr, 25 ns |
| Proportion | 0 instr, 11 ns |
| Proportion of large amounts | 0 instr, 12 ns |
| Addition, separately built currencies | 0 instr, 3 ns |
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
Host 'runnervmtr4k5' with 4 'x86_64' processors with 15 GB memory, running:
#22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026
```
## SwiftMoneyBenchmarks

### AnyCurrency storage for a custom field

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        11 |       105 |

### Control JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       520 |       520 |       520 |       520 |       520 |       520 |       520 |         2 |

### Control JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         3 |
| Time (wall clock) (ns) * |       492 |       492 |       493 |       495 |       495 |       495 |       495 |         3 |

### Currency construction, custom

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       110 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        10 |       110 |

### Currency description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        53 |
| Time (wall clock) (ns) * |        19 |        19 |        19 |        19 |        19 |        20 |        20 |        53 |

### Currency equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       490 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       490 |

### CurrencyCode description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        41 |

### CurrencyCode equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       446 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       446 |

### CurrencyCode validation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        25 |        25 |        25 |        25 |        25 |        25 |        25 |        41 |

### CurrencyCode validation, eight characters

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        24 |
| Time (wall clock) (ns) * |        42 |        43 |        43 |        43 |        43 |        43 |        43 |        24 |

### CurrencyCode validation, lowercase

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        25 |        25 |        41 |

### Decimal JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       614 |       614 |       614 |       615 |       615 |       615 |       615 |         2 |

### Decimal JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         2 |
| Time (wall clock) (ns) * |       714 |       714 |       714 |       714 |       714 |       714 |       714 |         2 |

### Decimal addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       172 |       173 |       173 |       173 |       173 |       173 |       173 |         6 |

### Decimal attributed, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        36 |        36 |        36 |        36 |        36 |        36 |        36 |         1 |
| Time (wall clock) (μs) * |        23 |        23 |        23 |        23 |        23 |        23 |        23 |         1 |

### Decimal chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1477 |      1477 |      1477 |      1477 |      1477 |      1477 |      1477 |         1 |

### Decimal comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        13 |
| Time (wall clock) (ns) * |        78 |        78 |        78 |        78 |        78 |        79 |        79 |        13 |

### Decimal description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       323 |       323 |       324 |       325 |       325 |       325 |       325 |         4 |

### Decimal divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1403 |      1403 |      1403 |      1403 |      1403 |      1403 |      1403 |         1 |

### Decimal format, ISO code, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2234 |      2234 |      2234 |      2234 |      2234 |      2234 |      2234 |         1 |

### Decimal format, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2185 |      2185 |      2185 |      2185 |      2185 |      2185 |      2185 |         1 |

### Decimal format, every option, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         1 |
| Time (wall clock) (ns) * |      2613 |      2613 |      2613 |      2613 |      2613 |      2613 |      2613 |         1 |

### Decimal format, full name, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2390 |      2390 |      2390 |      2390 |      2390 |      2390 |      2390 |         1 |

### Decimal format, grouping never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2916 |      2916 |      2916 |      2916 |      2916 |      2916 |      2916 |         1 |

### Decimal format, narrow, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2196 |      2196 |      2196 |      2196 |      2196 |      2196 |      2196 |         1 |

### Decimal format, precision 1dp and accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      2389 |      2389 |      2389 |      2389 |      2389 |      2389 |      2389 |         1 |

### Decimal format, precision 1dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2176 |      2176 |      2176 |      2176 |      2176 |      2176 |      2176 |         1 |

### Decimal format, precision 2dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2183 |      2183 |      2183 |      2183 |      2183 |      2183 |      2183 |         1 |

### Decimal format, separator always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2273 |      2273 |      2273 |      2273 |      2273 |      2273 |      2273 |         1 |

### Decimal format, sign accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      2441 |      2441 |      2441 |      2441 |      2441 |      2441 |      2441 |         1 |

### Decimal format, sign always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2356 |      2356 |      2356 |      2356 |      2356 |      2356 |      2356 |         1 |

### Decimal format, sign never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2351 |      2351 |      2351 |      2351 |      2351 |      2351 |      2351 |         1 |

### Decimal from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        65 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        15 |        15 |        16 |        16 |        65 |

### Decimal from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       291 |       291 |       291 |       291 |       291 |       291 |       291 |         4 |

### Decimal multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       353 |       353 |       353 |       353 |       353 |       353 |       353 |         3 |

### Decimal parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2525 |      2525 |      2525 |      2525 |      2525 |      2525 |      2525 |         1 |

### Decimal parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       275 |       275 |       276 |       277 |       277 |       277 |       277 |         4 |

### Decimal scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       149 |       151 |       152 |       153 |       154 |       154 |       154 |         7 |

### Decimal scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      2883 |      2883 |      2883 |      2883 |      2883 |      2883 |      2883 |         1 |

### Decimal subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       168 |       168 |       168 |       169 |       170 |       170 |       170 |         6 |

### Double addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       513 |

### Double chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       210 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       210 |

### Double comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       442 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       442 |

### Double description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        23 |
| Time (wall clock) (ns) * |        44 |        45 |        45 |        45 |        45 |        46 |        46 |        23 |

### Double divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       250 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       250 |

### Double from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        30 |        30 |        30 |        30 |        30 |        30 |        30 |        34 |

### Double multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       243 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       243 |

### Double parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        35 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        29 |        29 |        31 |        31 |        35 |

### Double scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       513 |

### Double scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       253 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       253 |

### Double subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       507 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       507 |

### Engine format, accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       198 |       198 |       198 |       198 |       198 |       198 |       198 |         6 |

### Engine format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       185 |       186 |       186 |       186 |       188 |       188 |       188 |         6 |

### Engine format, grouped, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       231 |       231 |       231 |       231 |       231 |       231 |       231 |         5 |

### Engine format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       191 |       191 |       191 |       192 |       194 |       194 |       194 |         6 |

### ExchangeRate applying a margin

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        23 |        24 |        24 |        43 |

### ExchangeRate construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        42 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        42 |

### ExchangeRate construction, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        24 |        26 |        26 |        43 |

### ExchangeRate crossed

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        50 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        20 |        20 |        20 |        50 |

### FixedPoint addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       509 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       509 |

### FixedPoint chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        32 |
| Time (wall clock) (ns) * |        31 |        31 |        31 |        31 |        32 |        32 |        32 |        32 |

### FixedPoint comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       493 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       493 |

### FixedPoint scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       110 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |        10 |       110 |

### FixedPoint scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        80 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        13 |        13 |        13 |        13 |        80 |

### FixedPoint subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       510 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       510 |

### FractionLength construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       314 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       314 |

### Harness floor, a struct

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       347 |

### Harness floor, an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       514 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       514 |

### ISO currency lookup

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        98 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        15 |        15 |        98 |

### Int addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       513 |

### Int chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       442 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       442 |

### Int comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       444 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       444 |

### Int description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        20 |
| Time (wall clock) (ns) * |        52 |        52 |        53 |        53 |        53 |        53 |        53 |        20 |

### Int from MoneyOf minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       313 |

### Int hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        29 |        30 |        30 |        30 |        34 |

### Int parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       128 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         9 |       128 |

### Int quotient and remainder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       313 |

### Int scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       503 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       503 |

### Int scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1435 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |      1435 |

### Int subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       513 |

### Int128 addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       488 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       488 |

### Int128 chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       121 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       121 |

### Int128 comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       443 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       443 |

### Int128 scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       347 |

### Int128 scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       343 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       343 |

### Int128 subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       489 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       489 |

### Margin construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       122 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         9 |         9 |       122 |

### Money JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1179 |      1179 |      1179 |      1179 |      1179 |      1179 |      1179 |         1 |

### Money JSON decode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        24 |        24 |        24 |        24 |        24 |        24 |        24 |         1 |
| Time (wall clock) (ns) * |      4825 |      4825 |      4825 |      4825 |      4825 |      4825 |      4825 |         1 |

### Money JSON decode, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1519 |      1519 |      1519 |      1519 |      1519 |      1519 |      1519 |         1 |

### Money JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         2 |
| Time (wall clock) (ns) * |       723 |       723 |       723 |       723 |       723 |       723 |       723 |         2 |

### Money JSON encode, major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1007 |      1007 |      1007 |      1007 |      1007 |      1007 |      1007 |         1 |

### Money JSON encode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2785 |      2785 |      2785 |      2785 |      2785 |      2785 |      2785 |         1 |

### Money Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        27 |
| Time (wall clock) (ns) * |        37 |        38 |        38 |        38 |        38 |        39 |        39 |        27 |

### Money addition in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         5 |         7 |       309 |

### Money addition, separately built currencies

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       313 |

### Money addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       347 |

### Money applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       167 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       167 |

### Money bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        56 |
| Time (wall clock) (ns) * |        18 |        18 |        18 |        18 |        18 |        18 |        18 |        56 |

### Money bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        58 |
| Time (wall clock) (ns) * |        17 |        17 |        17 |        17 |        17 |        17 |        17 |        58 |

### Money description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        36 |        36 |        36 |        36 |        36 |        36 |        29 |

### Money encode, no coder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       163 |       164 |       165 |       165 |       168 |       168 |       168 |         7 |

### Money encode, no coder, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       547 |       547 |       547 |       550 |       550 |       550 |       550 |         2 |

### Money equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       263 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       263 |

### Money format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1667 |      1667 |      1667 |      1667 |      1667 |      1667 |      1667 |         1 |

### Money from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       674 |       674 |       674 |       677 |       677 |       677 |       677 |         2 |

### Money hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        33 |        33 |        33 |        33 |        33 |        33 |        33 |        31 |

### Money init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       348 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       348 |

### Money is less than, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       441 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         4 |       441 |

### Money is multiple, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       383 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         3 |         5 |         5 |       383 |

### Money parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      3796 |      3796 |      3796 |      3796 |      3796 |      3796 |      3796 |         1 |

### Money parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        39 |
| Time (wall clock) (ns) * |        25 |        26 |        26 |        26 |        26 |        26 |        26 |        39 |

### Money parsing, caller's currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        49 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        20 |        21 |        21 |        49 |

### Money parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        25 |        25 |        25 |        25 |        25 |        25 |        25 |        41 |

### Money proportion, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        84 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        14 |        14 |        84 |

### Money scalar multiplication, amount times integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       285 |

### Money scalar multiplication, integer times amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       285 |

### Money split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         6 |
| Time (wall clock) (ns) * |       183 |       183 |       183 |       184 |       184 |       184 |       184 |         6 |

### Money split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       705 |       705 |       705 |       706 |       706 |       706 |       706 |         2 |

### Money split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       115 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |         9 |       115 |

### Money subtraction in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       509 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       509 |

### Money subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       313 |

### Money total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       133 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         8 |         8 |         8 |       133 |

### Money total of 1000, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       632 |       632 |       632 |       633 |       633 |       633 |       633 |         2 |

### Money unrounded addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       257 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       257 |

### Money unrounded applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        48 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        21 |        21 |        21 |        21 |        48 |

### Money unrounded divided by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        87 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        12 |        12 |        12 |        12 |        87 |

### Money unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        90 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        90 |

### Money unrounded minus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       243 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       243 |

### Money unrounded plus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       286 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         4 |       286 |

### Money unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |        10 |        11 |       105 |

### Money unrounded scaling by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        48 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        21 |        21 |        21 |        21 |        48 |

### Money unrounded scaling by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       159 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         7 |       159 |

### Money unrounded subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       257 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       257 |

### Money unrounded total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       126 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         9 |       126 |

### MoneyCodingFormat custom fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         3 |
| Time (wall clock) (ns) * |       413 |       413 |       415 |       415 |       415 |       415 |       415 |         3 |

### MoneyLocalization moneyFormat, ISO code, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       836 |       836 |       836 |       838 |       838 |       838 |       838 |         2 |

### MoneyLocalization moneyFormat, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       811 |       812 |       812 |       812 |       812 |       812 |       812 |         2 |

### MoneyOf JSON decode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      1690 |      1690 |      1690 |      1690 |      1690 |      1690 |      1690 |         1 |

### MoneyOf JSON encode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       970 |       970 |       970 |       970 |       970 |       970 |       970 |         2 |

### MoneyOf Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        33 |        33 |        31 |

### MoneyOf Unrounded bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        33 |
| Time (wall clock) (ns) * |        31 |        31 |        31 |        31 |        31 |        31 |        31 |        33 |

### MoneyOf addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       514 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       514 |

### MoneyOf addition in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       513 |

### MoneyOf addition near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1435 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |      1435 |

### MoneyOf applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       167 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       167 |

### MoneyOf attributed, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        35 |        35 |        35 |        35 |        35 |        35 |        35 |         1 |
| Time (wall clock) (μs) * |        32 |        32 |        32 |        32 |        32 |        32 |        32 |         1 |

### MoneyOf bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        64 |
| Time (wall clock) (ns) * |        16 |        16 |        16 |        16 |        16 |        16 |        16 |        64 |

### MoneyOf bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        48 |
| Time (wall clock) (ns) * |        20 |        21 |        21 |        21 |        21 |        21 |        21 |        48 |

### MoneyOf bytes encode, extremes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        48 |
| Time (wall clock) (ns) * |        20 |        21 |        21 |        21 |        21 |        21 |        21 |        48 |

### MoneyOf chain, rounding each step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        35 |        35 |        36 |        36 |        29 |

### MoneyOf comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       489 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       489 |

### MoneyOf converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       167 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       167 |

### MoneyOf currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       613 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       613 |

### MoneyOf description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        26 |
| Time (wall clock) (ns) * |        38 |        38 |        38 |        38 |        39 |        39 |        39 |        26 |

### MoneyOf description, large negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         8 |
| Time (wall clock) (ns) * |       135 |       135 |       135 |       135 |       135 |       135 |       135 |         8 |

### MoneyOf equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       263 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       263 |

### MoneyOf format, ISO code, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1731 |      1731 |      1731 |      1731 |      1731 |      1731 |      1731 |         1 |

### MoneyOf format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1645 |      1645 |      1645 |      1645 |      1645 |      1645 |      1645 |         1 |

### MoneyOf format, every option, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1824 |      1824 |      1824 |      1824 |      1824 |      1824 |      1824 |         1 |

### MoneyOf format, full name, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
| Time (wall clock) (ns) * |      1954 |      1954 |      1954 |      1954 |      1954 |      1954 |      1954 |         1 |

### MoneyOf format, grouping never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1657 |      1657 |      1657 |      1657 |      1657 |      1657 |      1657 |         1 |

### MoneyOf format, increment, en_GB [ICU fallback]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2782 |      2782 |      2782 |      2782 |      2782 |      2782 |      2782 |         1 |

### MoneyOf format, narrow, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1690 |      1690 |      1690 |      1690 |      1690 |      1690 |      1690 |         1 |

### MoneyOf format, precision 1dp and accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1748 |      1748 |      1748 |      1748 |      1748 |      1748 |      1748 |         1 |

### MoneyOf format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1692 |      1692 |      1692 |      1692 |      1692 |      1692 |      1692 |         1 |

### MoneyOf format, precision 2dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1699 |      1699 |      1699 |      1699 |      1699 |      1699 |      1699 |         1 |

### MoneyOf format, separator always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1629 |      1629 |      1629 |      1629 |      1629 |      1629 |      1629 |         1 |

### MoneyOf format, sign accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1686 |      1686 |      1686 |      1686 |      1686 |      1686 |      1686 |         1 |

### MoneyOf format, sign always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1664 |      1664 |      1664 |      1664 |      1664 |      1664 |      1664 |         1 |

### MoneyOf format, sign never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1664 |      1664 |      1664 |      1664 |      1664 |      1664 |      1664 |         1 |

### MoneyOf from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       678 |       678 |       678 |       680 |       680 |       680 |       680 |         2 |

### MoneyOf from a negative Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       740 |       740 |       740 |       743 |       743 |       743 |       743 |         2 |

### MoneyOf hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        34 |
| Time (wall clock) (ns) * |        29 |        29 |        29 |        30 |        30 |        30 |        30 |        34 |

### MoneyOf init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       348 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       348 |

### MoneyOf is multiple

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       411 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       411 |

### MoneyOf is negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       513 |

### MoneyOf is positive

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       497 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       497 |

### MoneyOf is zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       514 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       514 |

### MoneyOf magnitude

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       218 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         5 |         6 |         6 |         6 |       218 |

### MoneyOf negation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       285 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         5 |       285 |

### MoneyOf parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      3950 |      3950 |      3950 |      3950 |      3950 |      3950 |      3950 |         1 |

### MoneyOf parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        62 |
| Time (wall clock) (ns) * |        16 |        16 |        16 |        16 |        16 |        16 |        16 |        62 |

### MoneyOf parsing a large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        27 |
| Time (wall clock) (ns) * |        38 |        38 |        38 |        38 |        38 |        40 |        40 |        27 |

### MoneyOf parsing a negative amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        66 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        15 |        15 |        16 |        16 |        66 |

### MoneyOf parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        55 |
| Time (wall clock) (ns) * |        18 |        18 |        18 |        18 |        18 |        19 |        19 |        55 |

### MoneyOf proportion

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        87 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        12 |        12 |        12 |        87 |

### MoneyOf proportion of large amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        80 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        13 |        13 |        13 |        13 |        80 |

### MoneyOf scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       503 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       503 |

### MoneyOf scalar multiplication in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       313 |

### MoneyOf scalar multiplication near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       314 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       314 |

### MoneyOf scalar multiplication, Int32 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       313 |

### MoneyOf scalar multiplication, Int64 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       500 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       500 |

### MoneyOf scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        92 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        92 |

### MoneyOf scaled and rounded, large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        81 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        81 |

### MoneyOf split by 10 weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         4 |
| Time (wall clock) (ns) * |       307 |       307 |       308 |       308 |       308 |       308 |       308 |         4 |

### MoneyOf split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         6 |
| Time (wall clock) (ns) * |       186 |       186 |       186 |       187 |       189 |       189 |       189 |         6 |

### MoneyOf split by weights that divide exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         8 |
| Time (wall clock) (ns) * |       126 |       126 |       127 |       127 |       127 |       127 |       127 |         8 |

### MoneyOf split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       648 |       648 |       648 |       648 |       648 |       648 |       648 |         2 |

### MoneyOf split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       120 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       120 |

### MoneyOf split, iterating the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       114 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |        12 |       114 |

### MoneyOf subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       513 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       513 |

### MoneyOf total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       167 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       167 |

### MoneyOf total of 1000

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       320 |       320 |       320 |       320 |       320 |       320 |       320 |         4 |

### MoneyOf unrounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       313 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       313 |

### MoneyOf unrounded addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       262 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       262 |

### MoneyOf unrounded chain

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        65 |        65 |        65 |        65 |        65 |        67 |        67 |        16 |

### MoneyOf unrounded converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        48 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        21 |        21 |        21 |        21 |        48 |

### MoneyOf unrounded divided

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        87 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        12 |        12 |        12 |        87 |

### MoneyOf unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        93 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        12 |        12 |        93 |

### MoneyOf unrounded from major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        66 |        66 |        66 |        66 |        66 |        67 |        67 |        16 |

### MoneyOf unrounded from minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       312 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         5 |       312 |

### MoneyOf unrounded minus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       242 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       242 |

### MoneyOf unrounded plus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       262 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       262 |

### MoneyOf unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       109 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |         9 |       109 |

### MoneyOf unrounded scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        50 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        20 |        20 |        20 |        50 |

### MoneyOf unrounded subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       262 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       262 |

### MoneyOf unrounded times an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       166 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         7 |       166 |

### MoneyOf unrounded total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       159 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       159 |

### MoneyOf unroundedBytes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        32 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        33 |        33 |        32 |

### PartCount construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       343 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         4 |         5 |       343 |

### Rate equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       495 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       495 |

### Rate from a Double

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       213 |       214 |       214 |       214 |       217 |       217 |       217 |         5 |

### Rate from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        17 |
| Time (wall clock) (ns) * |        62 |        62 |        62 |        62 |        62 |        62 |        62 |        17 |

### Rate from a fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       182 |       182 |       182 |       182 |       182 |       182 |       182 |         6 |

### Rate from a large decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       150 |       150 |       150 |       150 |       150 |       150 |       150 |         7 |

### Rate from a negative decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        66 |        66 |        66 |        66 |        66 |        66 |        66 |        16 |

### Rate from a negative fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       214 |       214 |       214 |       214 |       217 |       217 |       217 |         5 |

### Rate from a percent string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |       108 |       108 |       108 |       108 |       108 |       110 |       110 |        10 |

### Rate from a string literal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        18 |
| Time (wall clock) (ns) * |        56 |        56 |        56 |        56 |        56 |        56 |        56 |        18 |

### Rate from basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       243 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       243 |

### Rate from percent

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       242 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       242 |

### Rate to basis points, rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        86 |
| Time (wall clock) (ns) * |        11 |        11 |        12 |        12 |        12 |        12 |        12 |        86 |

### Rate to whole basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       101 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        10 |        11 |       101 |

### Split counting the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       536 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       536 |

### UnitPrice total for a fractional quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        50 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        20 |        20 |        20 |        50 |

### UnitPrice total for a whole quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       186 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         6 |         7 |       186 |

### UnitScale construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       159 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       159 |

### UnitScale from decimal places

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       314 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       314 |

### Weight construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       347 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       347 |

### WeightedSplit amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        25 |
| Time (wall clock) (ns) * |        40 |        40 |        41 |        41 |        41 |        41 |        41 |        25 |

### WeightedSplit count

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       512 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       512 |

### WeightedSplit weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        25 |
| Time (wall clock) (ns) * |        41 |        41 |        42 |        42 |        42 |        42 |        42 |        25 |

### Weights construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        37 |
| Time (wall clock) (ns) * |        27 |        27 |        27 |        27 |        27 |        27 |        27 |        37 |


<!-- BENCHMARK-END -->

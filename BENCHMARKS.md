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
| Addition | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 175 ns |
| Subtraction | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 168 ns |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 137 ns |
| Scale and round | 0 instr, 11 ns | 0 instr, 1 ns | 0 instr, 4 ns | 0 instr, 2928 ns |
| Comparison | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 2 ns | 0 instr, 83 ns |
| Split into 3 | 0 instr, 9 ns | 0 instr, 4 ns | 0 instr, 4 ns | 0 instr, 1419 ns |
| Chained scaling | 0 instr, 69 ns | 0 instr, 2 ns | 0 instr, 6 ns | 0 instr, 1482 ns |

### Formatting, option by option, against Foundation

| Operation | Ours | Decimal | Speedup |
|:----------|----------:|----------:|----------:|
| Default | 0 instr, 1567 ns | 0 instr, 4 allocs, 2009 ns | **∞** |
| Runtime currency | 0 instr, 1581 ns | 0 instr, 4 allocs, 2009 ns | **∞** |
| ISO code | 0 instr, 1630 ns | 0 instr, 4 allocs, 2092 ns | **∞** |
| Narrow symbol | 0 instr, 1590 ns | 0 instr, 4 allocs, 2050 ns | **∞** |
| Full name | 0 instr, 1 alloc, 1905 ns | 0 instr, 5 allocs, 2204 ns | **∞** |
| Sign, never | 0 instr, 1560 ns | 0 instr, 5 allocs, 2178 ns | **∞** |
| Sign, always | 0 instr, 1633 ns | 0 instr, 5 allocs, 2175 ns | **∞** |
| Sign, accounting | 0 instr, 1633 ns | 0 instr, 6 allocs, 2250 ns | **∞** |
| Grouping, never | 0 instr, 1576 ns | 0 instr, 4 allocs, 2717 ns | **∞** |
| Decimal separator, always | 0 instr, 1573 ns | 0 instr, 5 allocs, 2143 ns | **∞** |
| Precision, 2dp | 0 instr, 1624 ns | 0 instr, 4 allocs, 2013 ns | **∞** |
| Precision, 1dp | 0 instr, 1629 ns | 0 instr, 4 allocs, 2003 ns | **∞** |
| Precision and accounting | 0 instr, 1681 ns | 0 instr, 6 allocs, 2208 ns | **∞** |
| Every option | 0 instr, 1735 ns | 0 instr, 7 allocs, 2398 ns | **∞** |
| Rounding increment | 0 instr, 4 allocs, 2404 ns | n/a | n/a |
| Attributed | 0 instr, 35 allocs, 35000 ns | 0 instr, 36 allocs, 24000 ns | **∞** |
| Parse | 0 instr, 5 allocs, 3405 ns | 0 instr, 5 allocs, 2327 ns | **∞** |

### Typed currency against runtime currency

| Operation | Ours | Money | Speedup |
|:----------|----------:|----------:|----------:|
| Addition | 0 instr, 2 ns | 0 instr, 3 ns | **∞** |
| Subtraction | 0 instr, 2 ns | 0 instr, 3 ns | **∞** |
| Scalar multiplication | 0 instr, 2 ns | 0 instr, 4 ns | **∞** |
| Applying a rate | 0 instr, 6 ns | 0 instr, 6 ns | **∞** |
| Equality | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Hashing | 0 instr, 33 ns | 0 instr, 35 ns | **∞** |
| Construction, checked | 0 instr, 3 ns | 0 instr, 4 ns | **∞** |
| Description | 0 instr, 38 ns | 0 instr, 36 ns | **∞** |
| Parsing | 0 instr, 17 ns | 0 instr, 26 ns | **∞** |
| Proportion | 0 instr, 11 ns | 0 instr, 11 ns | **∞** |
| Split into 3 | 0 instr, 9 ns | 0 instr, 10 ns | **∞** |
| Split by weights | 0 instr, 4 allocs, 172 ns | 0 instr, 4 allocs, 168 ns | **∞** |
| Total of 10 | 0 instr, 6 ns | 0 instr, 7 ns | **∞** |
| Bytes encode | 0 instr, 23 ns | 0 instr, 16 ns | **∞** |
| Bytes decode | 0 instr, 13 ns | 0 instr, 16 ns | **∞** |
| Unrounded addition | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded subtraction | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded plus settled | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded minus settled | 0 instr, 4 ns | 0 instr, 4 ns | **∞** |
| Unrounded scaling by a rate | 0 instr, 22 ns | 0 instr, 23 ns | **∞** |
| Unrounded times an integer | 0 instr, 6 ns | 0 instr, 6 ns | **∞** |
| Unrounded divided | 0 instr, 11 ns | 0 instr, 12 ns | **∞** |
| Unrounded divided exactly | 0 instr, 10 ns | 0 instr, 11 ns | **∞** |
| Unrounded rounded | 0 instr, 10 ns | 0 instr, 11 ns | **∞** |
| Unrounded total of 10 | 0 instr, 9 ns | 0 instr, 9 ns | **∞** |
| Unrounded bytes decode | 0 instr, 32 ns | 0 instr, 34 ns | **∞** |

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
| Scale, leaving it unrounded | 0 instr, 22 ns |
| Unrounded addition | 0 instr, 4 ns |
| Chained scaling, rounding each step | 0 instr, 36 ns |
| Rate from basis points | 0 instr, 4 ns |
| Rate from a decimal string | 0 instr, 63 ns |
| Exchange rate construction | 0 instr, 23 ns |
| Split into 3, runtime currency | 0 instr, 10 ns |
| Split, iterating the parts | 0 instr, 11 ns |
| Split into 1000, materialized | 0 instr, 1 alloc, 709 ns |
| Split by 10 weights | 0 instr, 4 allocs, 282 ns |
| Total of 10 | 0 instr, 6 ns |
| Total of 1000 | 0 instr, 361 ns |
| Currency code validation | 0 instr, 25 ns |
| Proportion | 0 instr, 11 ns |
| Proportion of large amounts | 0 instr, 12 ns |
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
Host 'runnervm8df0l' with 4 'x86_64' processors with 15 GB memory, running:
#22-Ubuntu SMP Mon Jul 27 17:24:03 UTC 2026
```
## SwiftMoneyBenchmarks

### AnyCurrency storage for a custom field

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       113 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |         9 |       113 |

### Control JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       516 |       516 |       516 |       519 |       519 |       519 |       519 |         2 |

### Control JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         3 |
| Time (wall clock) (ns) * |       444 |       444 |       444 |       446 |       446 |       446 |       446 |         3 |

### Currency construction, custom

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |        10 |        10 |        10 |       105 |

### Currency description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        54 |
| Time (wall clock) (ns) * |        19 |        19 |        19 |        19 |        19 |        19 |        19 |        54 |

### Currency equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       439 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       439 |

### CurrencyCode description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        24 |        24 |        41 |

### CurrencyCode equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       453 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       453 |

### CurrencyCode validation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        40 |
| Time (wall clock) (ns) * |        25 |        25 |        25 |        25 |        26 |        26 |        26 |        40 |

### CurrencyCode validation, eight characters

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        21 |
| Time (wall clock) (ns) * |        49 |        49 |        49 |        49 |        49 |        49 |        49 |        21 |

### CurrencyCode validation, lowercase

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        41 |
| Time (wall clock) (ns) * |        25 |        25 |        25 |        25 |        25 |        25 |        25 |        41 |

### Decimal JSON decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       598 |       599 |       599 |       599 |       599 |       599 |       599 |         2 |

### Decimal JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         2 |
| Time (wall clock) (ns) * |       656 |       656 |       656 |       656 |       656 |       656 |       656 |         2 |

### Decimal addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       174 |       175 |       175 |       175 |       175 |       175 |       175 |         6 |

### Decimal attributed, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        36 |        36 |        36 |        36 |        36 |        36 |        36 |         1 |
| Time (wall clock) (μs) * |        24 |        24 |        24 |        24 |        24 |        24 |        24 |         1 |

### Decimal chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1482 |      1482 |      1482 |      1482 |      1482 |      1482 |      1482 |         1 |

### Decimal comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        12 |
| Time (wall clock) (ns) * |        83 |        83 |        83 |        84 |        84 |        84 |        84 |        12 |

### Decimal description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       315 |       316 |       316 |       316 |       316 |       316 |       316 |         4 |

### Decimal divided by 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1419 |      1419 |      1419 |      1419 |      1419 |      1419 |      1419 |         1 |

### Decimal format, ISO code, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2092 |      2092 |      2092 |      2092 |      2092 |      2092 |      2092 |         1 |

### Decimal format, default, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2009 |      2009 |      2009 |      2009 |      2009 |      2009 |      2009 |         1 |

### Decimal format, every option, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         7 |         7 |         7 |         7 |         7 |         7 |         7 |         1 |
| Time (wall clock) (ns) * |      2398 |      2398 |      2398 |      2398 |      2398 |      2398 |      2398 |         1 |

### Decimal format, full name, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2204 |      2204 |      2204 |      2204 |      2204 |      2204 |      2204 |         1 |

### Decimal format, grouping never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2717 |      2717 |      2717 |      2717 |      2717 |      2717 |      2717 |         1 |

### Decimal format, narrow, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2050 |      2050 |      2050 |      2050 |      2050 |      2050 |      2050 |         1 |

### Decimal format, precision 1dp and accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      2208 |      2208 |      2208 |      2208 |      2208 |      2208 |      2208 |         1 |

### Decimal format, precision 1dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2003 |      2003 |      2003 |      2003 |      2003 |      2003 |      2003 |         1 |

### Decimal format, precision 2dp, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2013 |      2013 |      2013 |      2013 |      2013 |      2013 |      2013 |         1 |

### Decimal format, separator always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2143 |      2143 |      2143 |      2143 |      2143 |      2143 |      2143 |         1 |

### Decimal format, sign accounting, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      2250 |      2250 |      2250 |      2250 |      2250 |      2250 |      2250 |         1 |

### Decimal format, sign always, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2175 |      2175 |      2175 |      2175 |      2175 |      2175 |      2175 |         1 |

### Decimal format, sign never, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2178 |      2178 |      2178 |      2178 |      2178 |      2178 |      2178 |         1 |

### Decimal from MoneyOf

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        64 |
| Time (wall clock) (ns) * |        16 |        16 |        16 |        16 |        16 |        16 |        16 |        64 |

### Decimal from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       282 |       283 |       283 |       283 |       283 |       283 |       283 |         4 |

### Decimal multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       335 |       335 |       335 |       335 |       335 |       335 |       335 |         3 |

### Decimal parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      2327 |      2327 |      2327 |      2327 |      2327 |      2327 |      2327 |         1 |

### Decimal parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         4 |
| Time (wall clock) (ns) * |       274 |       274 |       274 |       275 |       275 |       275 |       275 |         4 |

### Decimal scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         8 |
| Time (wall clock) (ns) * |       136 |       137 |       137 |       137 |       139 |       139 |       139 |         8 |

### Decimal scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      2928 |      2928 |      2928 |      2928 |      2928 |      2928 |      2928 |         1 |

### Decimal subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       167 |       167 |       168 |       169 |       169 |       169 |       169 |         6 |

### Double addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Double chained scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       175 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       175 |

### Double comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       455 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       455 |

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
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        35 |
| Time (wall clock) (ns) * |        28 |        29 |        29 |        29 |        30 |        30 |        30 |        35 |

### Double multiplied by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       219 |
| Time (wall clock) (ns) * |         4 |         4 |         5 |         5 |         5 |         5 |         5 |       219 |

### Double parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        36 |
| Time (wall clock) (ns) * |        28 |        28 |        28 |        28 |        28 |        28 |        28 |        36 |

### Double scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Double scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       227 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       227 |

### Double subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Engine format, accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       195 |       196 |       196 |       196 |       197 |       197 |       197 |         6 |

### Engine format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       184 |       184 |       185 |       185 |       185 |       185 |       185 |         6 |

### Engine format, grouped, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         5 |
| Time (wall clock) (ns) * |       222 |       223 |       224 |       228 |       232 |       232 |       232 |         5 |

### Engine format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       193 |       193 |       193 |       193 |       193 |       193 |       193 |         6 |

### ExchangeRate applying a margin

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        40 |
| Time (wall clock) (ns) * |        25 |        25 |        25 |        25 |        25 |        27 |        27 |        40 |

### ExchangeRate construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        44 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        23 |        23 |        23 |        44 |

### ExchangeRate construction, across scales

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        42 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        25 |        25 |        42 |

### ExchangeRate crossed

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        45 |
| Time (wall clock) (ns) * |        22 |        22 |        22 |        22 |        22 |        23 |        23 |        45 |

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
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        81 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        81 |

### FixedPoint subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### FractionLength construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### Harness floor, a struct

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Harness floor, an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       543 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       543 |

### ISO currency lookup

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        98 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        10 |        10 |        98 |

### Int addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### Int chained scaling, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       402 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         4 |       402 |

### Int comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### Int description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        19 |
| Time (wall clock) (ns) * |        55 |        55 |        55 |        55 |        56 |        56 |        56 |        19 |

### Int from MoneyOf minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       308 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         5 |       308 |

### Int hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        33 |        33 |        33 |        33 |        33 |        33 |        31 |

### Int parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       127 |
| Time (wall clock) (ns) * |         8 |         8 |         8 |         8 |         8 |         8 |         8 |       127 |

### Int quotient and remainder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### Int scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       447 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       447 |

### Int scaled, truncating

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      1287 |
| Time (wall clock) (ns) * |         1 |         1 |         1 |         1 |         1 |         1 |         1 |      1287 |

### Int subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### Int128 addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       434 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       434 |

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
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       308 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       308 |

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
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      1134 |      1134 |      1134 |      1134 |      1134 |      1134 |      1134 |         1 |

### Money JSON decode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        24 |        24 |        24 |        24 |        24 |        24 |        24 |         1 |
| Time (wall clock) (ns) * |      4472 |      4472 |      4472 |      4472 |      4472 |      4472 |      4472 |         1 |

### Money JSON decode, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         6 |         6 |         6 |         6 |         6 |         6 |         6 |         1 |
| Time (wall clock) (ns) * |      1516 |      1516 |      1516 |      1516 |      1516 |      1516 |      1516 |         1 |

### Money JSON encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         2 |
| Time (wall clock) (ns) * |       607 |       607 |       607 |       608 |       608 |       608 |       608 |         2 |

### Money JSON encode, major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       926 |       926 |       926 |       931 |       931 |       931 |       931 |         2 |

### Money JSON encode, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        11 |        11 |        11 |        11 |        11 |        11 |        11 |         1 |
| Time (wall clock) (ns) * |      2572 |      2572 |      2572 |      2572 |      2572 |      2572 |      2572 |         1 |

### Money Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        30 |
| Time (wall clock) (ns) * |        34 |        34 |        34 |        34 |        34 |        35 |        35 |        30 |

### Money addition in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Money addition, separately built currencies

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### Money addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Money applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       175 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       175 |

### Money bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        62 |
| Time (wall clock) (ns) * |        16 |        16 |        16 |        16 |        16 |        23 |        23 |        62 |

### Money bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        63 |
| Time (wall clock) (ns) * |        15 |        16 |        16 |        16 |        16 |        17 |        17 |        63 |

### Money description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        28 |
| Time (wall clock) (ns) * |        36 |        36 |        36 |        36 |        37 |        37 |        37 |        28 |

### Money encode, no coder

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       156 |       156 |       156 |       156 |       159 |       159 |       159 |         7 |

### Money encode, no coder, two fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       502 |       503 |       503 |       506 |       506 |       506 |       506 |         2 |

### Money equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       233 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       233 |

### Money format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1581 |      1581 |      1581 |      1581 |      1581 |      1581 |      1581 |         1 |

### Money from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       646 |       646 |       646 |       646 |       646 |       646 |       646 |         2 |

### Money hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        35 |        35 |        35 |        36 |        36 |        36 |        36 |        29 |

### Money init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### Money init major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       187 |

### Money init major units, Int64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       187 |

### Money init major units, UInt32

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       187 |

### Money is less than, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       411 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       411 |

### Money is multiple, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       393 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         3 |         3 |       393 |

### Money parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      3308 |      3308 |      3308 |      3308 |      3308 |      3308 |      3308 |         1 |

### Money parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        39 |
| Time (wall clock) (ns) * |        26 |        26 |        26 |        26 |        26 |        26 |        26 |        39 |

### Money parsing, caller's currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        48 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        21 |        21 |        21 |        21 |        48 |

### Money parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        42 |
| Time (wall clock) (ns) * |        24 |        24 |        24 |        24 |        24 |        26 |        26 |        42 |

### Money proportion, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        88 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        12 |        12 |        12 |        88 |

### Money scalar multiplication, amount times integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       275 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       275 |

### Money scalar multiplication, integer times amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       276 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       276 |

### Money split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         6 |
| Time (wall clock) (ns) * |       167 |       168 |       168 |       168 |       168 |       168 |       168 |         6 |

### Money split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       787 |       787 |       787 |       788 |       788 |       788 |       788 |         2 |

### Money split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       102 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        10 |        10 |       102 |

### Money subtraction in place, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       441 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       441 |

### Money subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       308 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         4 |       308 |

### Money total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       134 |
| Time (wall clock) (ns) * |         7 |         7 |         7 |         7 |         7 |         8 |         9 |       134 |

### Money total of 1000, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       712 |       713 |       713 |       714 |       714 |       714 |       714 |         2 |

### Money unrounded addition, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       231 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       231 |

### Money unrounded applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        44 |
| Time (wall clock) (ns) * |        22 |        22 |        23 |        23 |        23 |        25 |        25 |        44 |

### Money unrounded divided by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        80 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        80 |

### Money unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        94 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        94 |

### Money unrounded minus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       228 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       228 |

### Money unrounded plus settled, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       254 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       254 |

### Money unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        94 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        94 |

### Money unrounded scaling by a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        45 |
| Time (wall clock) (ns) * |        22 |        22 |        23 |        23 |        23 |        23 |        23 |        45 |

### Money unrounded scaling by an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       156 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         7 |       156 |

### Money unrounded subtraction, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       232 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       232 |

### Money unrounded total of 10, throwing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       109 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |         9 |         9 |         9 |         9 |       109 |

### MoneyCodingFormat custom fields

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         2 |         2 |         2 |         2 |         2 |         2 |         2 |         3 |
| Time (wall clock) (ns) * |       392 |       392 |       392 |       394 |       394 |       394 |       394 |         3 |

### MoneyLocalization moneyFormat, ISO code, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       855 |       855 |       855 |       857 |       857 |       857 |       857 |         2 |

### MoneyLocalization moneyFormat, en_GB

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       826 |       826 |       826 |       826 |       826 |       826 |       826 |         2 |

### MoneyOf JSON decode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        10 |        10 |        10 |        10 |        10 |        10 |        10 |         1 |
| Time (wall clock) (ns) * |      1524 |      1524 |      1524 |      1524 |      1524 |      1524 |      1524 |         1 |

### MoneyOf JSON encode, amount only

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         2 |
| Time (wall clock) (ns) * |       880 |       880 |       880 |       884 |       884 |       884 |       884 |         2 |

### MoneyOf Unrounded bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        32 |        32 |        32 |        32 |        34 |        34 |        31 |

### MoneyOf Unrounded bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        30 |
| Time (wall clock) (ns) * |        34 |        34 |        34 |        34 |        34 |        35 |        35 |        30 |

### MoneyOf addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf addition in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf addition near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |      2360 |
| Time (wall clock) (ns) * |         0 |         0 |         0 |         0 |         0 |         0 |         1 |      2360 |

### MoneyOf applying a rate

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       175 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       175 |

### MoneyOf attributed, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |        35 |        35 |        35 |        35 |        35 |        35 |        35 |         1 |
| Time (wall clock) (μs) * |        35 |        35 |        35 |        35 |        35 |        35 |        35 |         1 |

### MoneyOf bytes decode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        79 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        13 |        13 |        13 |        79 |

### MoneyOf bytes encode

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        23 |        24 |        24 |        43 |

### MoneyOf bytes encode, extremes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        43 |
| Time (wall clock) (ns) * |        23 |        23 |        23 |        23 |        23 |        23 |        23 |        43 |

### MoneyOf chain, rounding each step

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        28 |
| Time (wall clock) (ns) * |        36 |        36 |        36 |        36 |        36 |        36 |        36 |        28 |

### MoneyOf comparison

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       457 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       457 |

### MoneyOf converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       176 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       176 |

### MoneyOf currency

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf description

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        27 |
| Time (wall clock) (ns) * |        37 |        38 |        38 |        38 |        38 |        39 |        39 |        27 |

### MoneyOf description, large negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         8 |
| Time (wall clock) (ns) * |       129 |       129 |       130 |       130 |       130 |       130 |       130 |         8 |

### MoneyOf equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       233 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       233 |

### MoneyOf format, ISO code, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1630 |      1630 |      1630 |      1630 |      1630 |      1630 |      1630 |         1 |

### MoneyOf format, default, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1567 |      1567 |      1567 |      1567 |      1567 |      1567 |      1567 |         1 |

### MoneyOf format, every option, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1735 |      1735 |      1735 |      1735 |      1735 |      1735 |      1735 |         1 |

### MoneyOf format, full name, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         1 |
| Time (wall clock) (ns) * |      1905 |      1905 |      1905 |      1905 |      1905 |      1905 |      1905 |         1 |

### MoneyOf format, grouping never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1576 |      1576 |      1576 |      1576 |      1576 |      1576 |      1576 |         1 |

### MoneyOf format, increment, en_GB [ICU fallback]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         1 |
| Time (wall clock) (ns) * |      2404 |      2404 |      2404 |      2404 |      2404 |      2404 |      2404 |         1 |

### MoneyOf format, narrow, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1590 |      1590 |      1590 |      1590 |      1590 |      1590 |      1590 |         1 |

### MoneyOf format, precision 1dp and accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1681 |      1681 |      1681 |      1681 |      1681 |      1681 |      1681 |         1 |

### MoneyOf format, precision 1dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1629 |      1629 |      1629 |      1629 |      1629 |      1629 |      1629 |         1 |

### MoneyOf format, precision 2dp, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1624 |      1624 |      1624 |      1624 |      1624 |      1624 |      1624 |         1 |

### MoneyOf format, separator always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1573 |      1573 |      1573 |      1573 |      1573 |      1573 |      1573 |         1 |

### MoneyOf format, sign accounting, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1633 |      1633 |      1633 |      1633 |      1633 |      1633 |      1633 |         1 |

### MoneyOf format, sign always, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1633 |      1633 |      1633 |      1633 |      1633 |      1633 |      1633 |         1 |

### MoneyOf format, sign never, en_GB [engine]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         1 |
| Time (wall clock) (ns) * |      1560 |      1560 |      1560 |      1560 |      1560 |      1560 |      1560 |         1 |

### MoneyOf from Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       668 |       668 |       668 |       669 |       669 |       669 |       669 |         2 |

### MoneyOf from a negative Decimal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         2 |
| Time (wall clock) (ns) * |       702 |       703 |       703 |       703 |       703 |       703 |       703 |         2 |

### MoneyOf hashing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        31 |
| Time (wall clock) (ns) * |        32 |        33 |        33 |        33 |        33 |        33 |        33 |        31 |

### MoneyOf init exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### MoneyOf init major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         6 |       187 |

### MoneyOf init major units, Int64

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       187 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       187 |

### MoneyOf init major units, UInt32

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       200 |
| Time (wall clock) (ns) * |         5 |         5 |         5 |         5 |         5 |         5 |         5 |       200 |

### MoneyOf is multiple

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       400 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         3 |         3 |         3 |         3 |       400 |

### MoneyOf is negative

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       454 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       454 |

### MoneyOf is positive

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       444 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       444 |

### MoneyOf is zero

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf magnitude

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### MoneyOf negation

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### MoneyOf parse, en_GB [ICU]

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         5 |         5 |         5 |         5 |         5 |         5 |         5 |         1 |
| Time (wall clock) (ns) * |      3405 |      3405 |      3405 |      3405 |      3405 |      3405 |      3405 |         1 |

### MoneyOf parsing

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        58 |
| Time (wall clock) (ns) * |        17 |        17 |        17 |        17 |        17 |        17 |        17 |        58 |

### MoneyOf parsing a large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        24 |
| Time (wall clock) (ns) * |        43 |        43 |        43 |        43 |        43 |        43 |        43 |        24 |

### MoneyOf parsing a negative amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        65 |
| Time (wall clock) (ns) * |        15 |        15 |        15 |        15 |        15 |        16 |        16 |        65 |

### MoneyOf parsing, whole major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        51 |
| Time (wall clock) (ns) * |        20 |        20 |        20 |        20 |        20 |        20 |        20 |        51 |

### MoneyOf proportion

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        91 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        91 |

### MoneyOf proportion of large amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        82 |
| Time (wall clock) (ns) * |        12 |        12 |        12 |        12 |        12 |        13 |        13 |        82 |

### MoneyOf scalar multiplication

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       447 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       447 |

### MoneyOf scalar multiplication in place

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       276 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       276 |

### MoneyOf scalar multiplication near the maximum

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       254 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       254 |

### MoneyOf scalar multiplication, Int32 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### MoneyOf scalar multiplication, Int64 operand

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       456 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       456 |

### MoneyOf scaled and rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        94 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        94 |

### MoneyOf scaled and rounded, large amount

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        85 |
| Time (wall clock) (ns) * |        11 |        12 |        12 |        12 |        12 |        13 |        13 |        85 |

### MoneyOf split by 10 weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         4 |
| Time (wall clock) (ns) * |       282 |       282 |       282 |       282 |       282 |       282 |       282 |         4 |

### MoneyOf split by weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         4 |         4 |         4 |         4 |         4 |         4 |         4 |         6 |
| Time (wall clock) (ns) * |       171 |       172 |       172 |       173 |       179 |       179 |       179 |         6 |

### MoneyOf split by weights that divide exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         3 |         3 |         3 |         3 |         3 |         3 |         3 |         8 |
| Time (wall clock) (ns) * |       127 |       128 |       128 |       128 |       128 |       128 |       128 |         8 |

### MoneyOf split into 1000, materialized

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |         2 |
| Time (wall clock) (ns) * |       709 |       709 |       709 |       709 |       709 |       709 |       709 |         2 |

### MoneyOf split into 3

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |        10 |        10 |        10 |        10 |       105 |

### MoneyOf split, iterating the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        94 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        11 |        11 |        94 |

### MoneyOf subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### MoneyOf total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       156 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       156 |

### MoneyOf total of 1000

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         3 |
| Time (wall clock) (ns) * |       361 |       361 |       361 |       361 |       361 |       361 |       361 |         3 |

### MoneyOf unrounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       308 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       308 |

### MoneyOf unrounded addition

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       232 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       232 |

### MoneyOf unrounded chain

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        15 |
| Time (wall clock) (ns) * |        69 |        69 |        69 |        69 |        69 |        70 |        70 |        15 |

### MoneyOf unrounded converted

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        44 |
| Time (wall clock) (ns) * |        22 |        23 |        23 |        23 |        23 |        23 |        23 |        44 |

### MoneyOf unrounded divided

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        88 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        12 |        12 |        88 |

### MoneyOf unrounded divided exactly

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        97 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        10 |        10 |        97 |

### MoneyOf unrounded from major units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        15 |
| Time (wall clock) (ns) * |        70 |        70 |        70 |        70 |        70 |        70 |        70 |        15 |

### MoneyOf unrounded from minor units

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### MoneyOf unrounded minus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       230 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         5 |       230 |

### MoneyOf unrounded plus settled

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       233 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       233 |

### MoneyOf unrounded rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        96 |
| Time (wall clock) (ns) * |        10 |        10 |        10 |        10 |        10 |        11 |        11 |        96 |

### MoneyOf unrounded scaling

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        46 |
| Time (wall clock) (ns) * |        22 |        22 |        22 |        22 |        22 |        22 |        22 |        46 |

### MoneyOf unrounded subtraction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       232 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         5 |         5 |       232 |

### MoneyOf unrounded times an integer

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       165 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         7 |         7 |       165 |

### MoneyOf unrounded total of 10

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       105 |
| Time (wall clock) (ns) * |         9 |         9 |         9 |        10 |        10 |        10 |        10 |       105 |

### MoneyOf unroundedBytes

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        29 |
| Time (wall clock) (ns) * |        34 |        34 |        34 |        34 |        36 |        42 |        42 |        29 |

### PartCount construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       309 |
| Time (wall clock) (ns) * |         3 |         3 |         3 |         3 |         3 |         3 |         3 |       309 |

### Rate equality

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       449 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         3 |       449 |

### Rate from a Double

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       183 |       184 |       184 |       185 |       185 |       185 |       185 |         6 |

### Rate from a decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        16 |
| Time (wall clock) (ns) * |        62 |        63 |        63 |        63 |        64 |        65 |        65 |        16 |

### Rate from a fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       163 |       163 |       163 |       163 |       164 |       164 |       164 |         7 |

### Rate from a large decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         7 |
| Time (wall clock) (ns) * |       147 |       147 |       147 |       147 |       147 |       147 |       147 |         7 |

### Rate from a negative decimal string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        15 |
| Time (wall clock) (ns) * |        67 |        67 |        67 |        67 |        68 |        68 |        68 |        15 |

### Rate from a negative fraction string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |         6 |
| Time (wall clock) (ns) * |       191 |       191 |       191 |       191 |       192 |       192 |       192 |         6 |

### Rate from a percent string

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        10 |
| Time (wall clock) (ns) * |       108 |       108 |       108 |       108 |       108 |       109 |       109 |        10 |

### Rate from a string literal

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        18 |
| Time (wall clock) (ns) * |        55 |        55 |        56 |        56 |        60 |        64 |        64 |        18 |

### Rate from basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       233 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       233 |

### Rate from percent

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       254 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       254 |

### Rate to basis points, rounded

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        77 |
| Time (wall clock) (ns) * |        13 |        13 |        13 |        13 |        13 |        13 |        13 |        77 |

### Rate to whole basis points

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        93 |
| Time (wall clock) (ns) * |        11 |        11 |        11 |        11 |        11 |        12 |        12 |        93 |

### Split counting the parts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       458 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       458 |

### UnitPrice total for a fractional quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |        47 |
| Time (wall clock) (ns) * |        21 |        21 |        21 |        21 |        22 |        22 |        22 |        47 |

### UnitPrice total for a whole quantity

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       166 |
| Time (wall clock) (ns) * |         6 |         6 |         6 |         6 |         6 |         6 |         6 |       166 |

### UnitScale construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       152 |
| Time (wall clock) (ns) * |         6 |         6 |         7 |         7 |         7 |         7 |         7 |       152 |

### UnitScale from decimal places

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       279 |
| Time (wall clock) (ns) * |         3 |         4 |         4 |         4 |         4 |         4 |         4 |       279 |

### Weight construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       278 |
| Time (wall clock) (ns) * |         4 |         4 |         4 |         4 |         4 |         4 |         4 |       278 |

### WeightedSplit amounts

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        24 |
| Time (wall clock) (ns) * |        42 |        43 |        43 |        43 |        43 |        43 |        43 |        24 |

### WeightedSplit count

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         0 |         0 |         0 |         0 |         0 |         0 |         0 |       453 |
| Time (wall clock) (ns) * |         2 |         2 |         2 |         2 |         2 |         2 |         2 |       453 |

### WeightedSplit weights

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        24 |
| Time (wall clock) (ns) * |        42 |        42 |        42 |        42 |        43 |        45 |        45 |        24 |

### Weights construction

| Metric                   |        p0 |       p25 |       p50 |       p75 |       p90 |       p99 |      p100 |   Samples |
|:-------------------------|----------:|----------:|----------:|----------:|----------:|----------:|----------:|----------:|
| Malloc (total) *         |         1 |         1 |         1 |         1 |         1 |         1 |         1 |        36 |
| Time (wall clock) (ns) * |        28 |        28 |        28 |        28 |        29 |        29 |        29 |        36 |


<!-- BENCHMARK-END -->

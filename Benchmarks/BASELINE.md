# Performance baseline

The reference the performance work is measured against (spec §16). Every change is a diff against these
numbers, so a regression or a win is measured, not impressioned. This captures the full public API — every
public operation a caller can run, common and edge cases — so a future regression anywhere is visible.

**Read the instruction column.** Wall-clock is noisy (CI gates it at 20% for that reason) and malloc is
near-zero across the arithmetic; the p50 **instruction count** is the stable signal, and it is the one no
CI runner exposes — which is exactly why it is captured here by hand.

Captured on Apple Silicon (arm64, macOS 26.6), Swift 6.2.4, release build, `scalingFactor: .mega`, p50 of
each metric. Reproduce with:

```sh
swift package --package-path Benchmarks --disable-sandbox --allow-writing-to-package-directory \
    benchmark --format markdown
```

## Where the fractional path landed

Addition, subtraction, scalar-multiply and comparison are `Int64` operations at `Int` parity, far ahead of
`Decimal`. The fractional operations carried the `Fixed`-engine regression, which the performance program
(PRs through the `Fixed` fast path) drove back down:

| Operation | start of Part II | now | FixedPointDecimal (peer) |
|---|--:|--:|--:|
| Scale by a rate and round | 2506 | 287 | 198 |
| Chained scaling (three rates) | 7454 | 869 | 530 |

`FixedPointDecimal` (ordo-one, `Int64`-backed, 8 fraction digits) is the same-class yardstick; `Int128`
(same storage width, truncating) shows the arithmetic floor beneath the renormalization (27 / 107). Scale-
and-round is now 1.45× the peer, down from ~12×.

Known outlier: **`WeightedSplit amounts` reads ~22K instructions** — the accessor is not specialized for a
typed currency (the same generic tax the weighted split itself had before it was made inlinable). A
candidate for the specialization sweep.

## Baselines

- **Int / Int128** — what type safety costs; `Int128` is the scaling engine's own width, truncating.
- **Double** — the fast answer that is wrong at scale.
- **FixedPointDecimal** — the closest published peer, same benchmark harness.
- **Decimal** — the exact answer that is slow.

### Addition

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf addition | 8 | 0 | 0 |
| Int addition | 8 | 0 | 0 |
| Int128 addition | 11 | 0 | 1 |
| Double addition | 6 | 0 | 1 |
| FixedPoint addition | 11 | 0 | 0 |
| Decimal addition | 7130 | 6 | 212 |

### Subtraction

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf subtraction | 8 | 0 | 0 |
| Int subtraction | 8 | 0 | 0 |
| Int128 subtraction | 11 | 0 | 1 |
| Double subtraction | 7 | 0 | 0 |
| FixedPoint subtraction | 11 | 0 | 0 |
| Decimal subtraction | 7829 | 7 | 237 |

### Scalar multiplication

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf scalar multiplication | 12 | 0 | 1 |
| Int scalar multiplication | 12 | 0 | 1 |
| Int128 scalar multiplication | 23 | 0 | 1 |
| Double scalar multiplication | 7 | 0 | 1 |
| FixedPoint scalar multiplication | 167 | 0 | 6 |
| Decimal scalar multiplication | 6240 | 5 | 178 |

### Scale by a rate and round

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf scaled and rounded | 287 | 0 | 12 |
| Int scaled, truncating | 6 | 0 | 0 |
| Int128 scaled, truncating | 27 | 0 | 1 |
| Double scaled and rounded | 7 | 0 | 1 |
| FixedPoint scaled and rounded | 198 | 0 | 8 |
| Decimal scaled and rounded | 107K | 83 | 3203 |

### Chained scaling (three rates)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf unrounded chain | 2135 | 0 | 89 |
| MoneyOf chain, rounding each step | 869 | 0 | 46 |
| Int chained scaling, truncating | 23 | 0 | 1 |
| Int128 chained scaling, truncating | 107 | 0 | 6 |
| Double chained scaling | 12 | 0 | 1 |
| FixedPoint chained scaling | 530 | 0 | 31 |
| Decimal chained scaling | 55K | 41 | 1644 |

### Unrounded (round-once) building blocks

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf unrounded scaling | 1138 | 0 | 46 |
| MoneyOf unrounded divided | 1736 | 0 | 69 |
| MoneyOf unrounded addition | 36 | 0 | 1 |
| MoneyOf unrounded subtraction | 36 | 0 | 1 |
| MoneyOf unrounded plus settled | 774 | 0 | 34 |
| MoneyOf unrounded minus settled | 774 | 0 | 24 |
| MoneyOf unrounded divided exactly | 1626 | 0 | 55 |

### Money.Unrounded (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money unrounded scaling by a rate | 444 | 0 | 15 |
| Money unrounded scaling by an integer | 743 | 0 | 24 |
| Money unrounded applying a rate | 444 | 0 | 15 |
| Money unrounded divided by an integer | 994 | 0 | 33 |
| Money unrounded divided exactly | 1183 | 0 | 36 |
| Money unrounded rounded | 275 | 0 | 9 |
| Money unrounded addition, throwing | 45 | 0 | 1 |
| Money unrounded subtraction, throwing | 45 | 0 | 1 |
| Money unrounded plus settled, throwing | 94 | 0 | 2 |

### Comparison

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf comparison | 13 | 0 | 0 |
| Int comparison | 13 | 0 | 0 |
| Int128 comparison | 15 | 0 | 1 |
| Double comparison | 13 | 0 | 0 |
| FixedPoint comparison | 13 | 0 | 0 |
| Decimal comparison | 3932 | 4 | 124 |

### Money (runtime currency) arithmetic

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money addition, throwing | 25 | 0 | 1 |
| Money addition, separately built currencies | 26 | 0 | 1 |
| Money subtraction, throwing | 34 | 0 | 1 |
| Money addition in place, throwing | 25 | 0 | 1 |
| Money scalar multiplication, amount times integer | 31 | 0 | 1 |
| Money scalar multiplication, integer times amount | 31 | 0 | 1 |
| Money applying a rate | 68 | 0 | 2 |
| Money is less than, throwing | 18 | 0 | 1 |
| Money proportion, throwing | 470 | 0 | 15 |
| Money is multiple, throwing | 20 | 0 | 1 |

### Description

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf description | 445 | 0 | 12 |
| Money description | 437 | 0 | 12 |
| Int description | 470 | 0 | 15 |
| Double description | 524 | 0 | 17 |
| Decimal description | 6654 | 3 | 208 |
| CurrencyCode description | 126 | 0 | 4 |

### Parsing

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money parsing | 274 | 0 | 7 |
| MoneyOf parsing | 211 | 0 | 6 |
| MoneyOf parsing a large amount | 624 | 0 | 16 |
| MoneyOf parsing a negative amount | 198 | 0 | 6 |
| Int parsing | 79 | 0 | 2 |
| Double parsing | 298 | 0 | 8 |
| Decimal parsing | 4749 | 2 | 167 |

### Decimal bridge

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf from Decimal | 18K | 11 | 552 |
| MoneyOf from a negative Decimal | 18K | 11 | 624 |
| Money from Decimal | 18K | 11 | 553 |
| Decimal from MoneyOf | 6338 | 5 | 188 |
| Int from MoneyOf minor units | 27 | 0 | 1 |

### Proportion

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf proportion | 449 | 0 | 15 |
| MoneyOf proportion of large amounts | 464 | 0 | 16 |

### Splitting

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Weights construction | 778 | 1 | 23 |
| MoneyOf split into 3 | 56 | 0 | 2 |
| Money split into 3 | 58 | 0 | 2 |
| MoneyOf split by weights | 4360 | 4 | 137 |
| Money split by weights | 4375 | 4 | 140 |
| MoneyOf split by weights that divide exactly | 3110 | 3 | 104 |
| WeightedSplit amounts | 22K | 9 | 706 |
| WeightedSplit weights | 22K | 9 | 706 |
| Int quotient and remainder | 28 | 0 | 1 |
| Double divided by 3 | 9 | 0 | 0 |
| Decimal divided by 3 | 50K | 37 | 1545 |
| MoneyOf split, iterating the parts | 6326 | 0 | 188 |
| Split counting the parts | 900 | 0 | 26 |

### Total

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf total of 10 | 87 | 0 | 3 |
| Money total of 10, throwing | 142 | 0 | 4 |
| MoneyOf unrounded total of 10 | 854 | 0 | 28 |
| Money unrounded total of 10, throwing | 160 | 0 | 5 |

### Currency & code

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| CurrencyCode validation | 244 | 0 | 8 |
| CurrencyCode validation, eight characters | 427 | 0 | 15 |
| ISO currency lookup | 87 | 0 | 3 |
| Currency construction, custom | 107 | 0 | 4 |
| UnitScale construction | 91 | 0 | 3 |

### Rate construction & conversion

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate from basis points | 971 | 0 | 31 |
| Rate from percent | 1008 | 0 | 32 |
| Rate from a decimal string | 1800 | 0 | 56 |
| Rate from a percent string | 2265 | 0 | 72 |
| Rate from a fraction string | 1934 | 0 | 60 |
| Rate from a large decimal string | 2066 | 0 | 62 |
| Rate from a negative decimal string | 1876 | 0 | 60 |
| Rate from a negative fraction string | 2239 | 0 | 73 |
| Rate from a string literal | 1792 | 0 | 57 |
| Double from a decimal string | 322 | 0 | 11 |
| Decimal from a decimal string | 4678 | 2 | 163 |
| Rate to whole basis points | 162 | 0 | 6 |
| Rate to basis points, rounded | 301 | 0 | 9 |
| Rate from a Double | 2575 | 0 | 83 |

### FX

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf converted | 1612 | 0 | 52 |
| ExchangeRate crossed | 368 | 0 | 11 |
| ExchangeRate applying a margin | 380 | 0 | 11 |
| Margin construction | 43 | 0 | 2 |
| Double multiplied by a rate | 9 | 0 | 1 |
| Decimal multiplied by a rate | 13K | 10 | 392 |

### UnitPrice

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| UnitPrice total for a whole quantity | 753 | 0 | 24 |
| UnitPrice total for a fractional quantity | 397 | 0 | 12 |
| MoneyOf unrounded from major units | 2373 | 0 | 69 |

### Value-type edge cases

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf negation | 28 | 0 | 1 |
| MoneyOf magnitude | 28 | 0 | 1 |
| MoneyOf is multiple | 14 | 0 | 1 |

### Codable / JSON

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money JSON encode | 7214 | 2 | 250 |
| Money JSON decode | 14K | 6 | 450 |
| Money JSON encode, two fields | 28K | 11 | 925 |
| Money JSON decode, two fields | 52K | 29 | 1723 |
| Money JSON encode, major units | 10K | 3 | 350 |
| MoneyOf JSON encode, amount only | 9719 | 3 | 347 |
| Control JSON encode | 5948 | 2 | 207 |
| Control JSON decode | 8417 | 6 | 282 |
| Decimal JSON encode | 11K | 5 | 361 |
| Decimal JSON decode | 12K | 8 | 388 |
| Money encode, no coder | 1285 | 0 | 42 |
| Money encode, no coder, two fields | 4312 | 1 | 132 |

### Binary serializer

Fixed fifteen bytes, no coder and no `String`, so it runs allocation-free and orders of magnitude below
every JSON row. The typed decode only checks the code and scale against the type's own; the runtime decode
rebuilds the currency, which is the table check it pays for. The `Unrounded` rows are the 23-byte peer;
`unroundedBytes` costs more because it widens a settled amount by 10^18 before encoding.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf bytes encode | 403 | 0 | 11 |
| MoneyOf bytes decode | 174 | 0 | 5 |
| Money bytes decode | 219 | 0 | 6 |
| MoneyOf Unrounded bytes encode | 627 | 0 | 16 |
| MoneyOf Unrounded bytes decode | 197 | 0 | 5 |
| Money Unrounded bytes decode | 241 | 0 | 6 |
| MoneyOf unroundedBytes | 1376 | 0 | 40 |

### Currency formatting, option by option

Recaptured on Swift 6.4, so these rows are not comparable with the Swift 6.2.4 numbers elsewhere in this
document; the ratios within the section are, every row here having been measured in one run.

Each row's name ends in the path it takes. **`[engine]`** renders through the Foundation-free engine with
no ICU at all. **`[ICU fallback]`** is this library handing the work to Foundation, which happens for any
explicit precision, any rounding increment, a sign strategy outside the four Foundation names, or a
locale the CLDR data does not cover — the rule is `engineRenderInputs` in `MoneyOf+FormatStyle.swift`.
**`[ICU]`** is Foundation's own `Decimal.FormatStyle.Currency`, the peer each option is measured against
with the same setting applied to both sides.

Two things stand out. Where the engine renders, it is roughly 2.3× to 4.7× cheaper than Foundation and,
since the packed tables landed, allocates nothing at all against ten to twenty times. A fixed fraction
length now renders in the engine too, so `precision 2dp` costs what the default does (8913 against 8596)
rather than the ~32K it cost when it fell back. What still falls back — a rounding increment,
significant-digit or range precision, a full name at an explicit precision, or an uncovered locale — is
about 1.4× **dearer** than calling Foundation directly, because it rebuilds the underlying style and
converts the amount on every call.

| Operation | Instructions | Malloc | Wall (ns) | Foundation | Malloc | Wall (ns) |
|---|--:|--:|--:|--:|--:|--:|
| Default `[engine]` | 8596 | 0 | 317 | 22K | 10 | 789 |
| Default, runtime currency `[engine]` | 8577 | 0 | 316 | 22K | 10 | 789 |
| ISO code `[engine]` | 8713 | 0 | 328 | 23K | 10 | 804 |
| Narrow symbol `[engine]` | 8651 | 0 | 323 | 23K | 10 | 803 |
| Full name `[engine]` | 13K | 1 | 466 | 25K | 11 | 859 |
| Sign, never `[engine]` | 8640 | 0 | 336 | 25K | 11 | 874 |
| Sign, always `[engine]` | 8750 | 0 | 337 | 25K | 11 | 866 |
| Sign, accounting `[engine]` | 8898 | 0 | 346 | 26K | 12 | 897 |
| Grouping, never `[engine]` | 8800 | 0 | 339 | 41K | 21 | 1373 |
| Decimal separator, always `[engine]` | 8596 | 0 | 317 | 24K | 11 | 840 |
| Precision, 2dp `[engine]` | 8913 | 0 | 349 | 22K | 10 | 804 |
| Precision, 1dp `[engine]` | 8857 | 0 | 345 | 22K | 10 | 797 |
| Precision 1dp and accounting `[engine]` | 9183 | 0 | 343 | 25K | 12 | 900 |
| Every option `[engine]` | 9292 | 0 | 346 | 21K | 10 | 732 |
| Rounding increment `[ICU fallback]` | 36K | 18 | 1264 | n/a | n/a | n/a |
| Attributed `[engine]` | 206K | 59 | 8915 | 146K | 39 | 5793 |
| Parse `[ICU]` | 46K | 19 | 1622 | 25K | 8 | 888 |
| Parse, runtime currency `[ICU]` | 45K | 19 | 1597 | 25K | 8 | 888 |

The rounding increment has no Foundation column: Foundation counts an increment in whole units where this
library counts the currency's smallest, and beside a pinned fraction length Foundation ignores the
increment and drops the currency symbol, so there is nothing equivalent to measure.

Rendering an `AttributedString` is the one output that is dearer than ICU's, because it builds the string
run by run. It exists for consistency with `format(_:)` rather than for speed.

### Non-ICU formatter engine (§15)

The Foundation-free engine measured directly, rendering with a prebuilt descriptor. Allocation-free and
~19× below ICU; grouping adds the per-separator work. `MoneyOf.FormatStyle` renders through this engine
for a covered locale (the rows above), building the descriptor from the packed CLDR tables on each call,
which is the whole of the gap between 1159 and 8531.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Engine format, default, en_GB `[engine]` | 1159 | 0 | 33 |
| Engine format, grouped, en_GB `[engine]` | 1640 | 0 | 50 |

### Harness floor

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 0 |

# Performance baseline

The reference performance work is measured against. Every change is a diff against these numbers, so a
regression or a win is measured, not impressioned. It covers every public `SwiftMoneyCore` operation that
does work, common and edge cases, grouped by the type that owns it. Stored-property reads and constants
(`currency`, `min`, `max`, `zero`, `Split.Group`'s fields, the coding-key literals) have no row of their own.

**Read the instruction column.** Wall-clock is noisy (CI gates it at 20% for that reason) and malloc is
near-zero across the arithmetic. The p50 **instruction count** is the stable signal, and no CI runner
exposes it, which is why it is captured here by hand. Every row includes handing its result to the harness:
7 instructions for an integer, 22 for a struct (see *Harness floor*).

Captured on Apple Silicon (arm64, macOS 26.6), Swift 6.4, release build, `scalingFactor: .mega`, p50 of
each metric. Reproduce with:

```sh
swift package --package-path Benchmarks --disable-sandbox --allow-writing-to-package-directory \
    benchmark --format markdown
```

## Where the fractional path stands

Addition, subtraction, scalar multiplication and comparison are `Int64` operations at `Int` parity, far
ahead of `Decimal`. The fractional operations are measured against the closest peer:

| Operation | Start of Part II | Now | FixedPointDecimal (peer) |
|---|--:|--:|--:|
| Scale by a rate and round | 2506 | 238 | 179 |
| Chained scaling (three rates) | 7454 | 719 | 473 |

## By type

### MoneyOf (typed currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Int from MoneyOf minor units | 29 | 0 | 1 |
| MoneyOf addition | 9 | 0 | 1 |
| MoneyOf addition in place | 9 | 0 | 1 |
| MoneyOf addition near the maximum | 8 | 0 | 0 |
| MoneyOf applying a rate | 57 | 0 | 2 |
| MoneyOf comparison | 15 | 0 | 1 |
| MoneyOf currency | 10 | 0 | 0 |
| MoneyOf description | 403 | 0 | 12 |
| MoneyOf description, large negative | 1592 | 1 | 68 |
| MoneyOf equality | 7 | 0 | 1 |
| MoneyOf hashing | 152 | 0 | 7 |
| MoneyOf init exactly | 25 | 0 | 1 |
| MoneyOf is multiple | 16 | 0 | 1 |
| MoneyOf is negative | 10 | 0 | 1 |
| MoneyOf is positive | 7 | 0 | 0 |
| MoneyOf is zero | 7 | 0 | 0 |
| MoneyOf magnitude | 30 | 0 | 1 |
| MoneyOf negation | 29 | 0 | 1 |
| MoneyOf parsing | 227 | 0 | 6 |
| MoneyOf parsing a large amount | 661 | 0 | 17 |
| MoneyOf parsing a negative amount | 204 | 0 | 6 |
| MoneyOf parsing, whole major units | 263 | 0 | 7 |
| MoneyOf proportion | 229 | 0 | 7 |
| MoneyOf proportion of large amounts | 280 | 0 | 11 |
| MoneyOf scalar multiplication | 14 | 0 | 1 |
| MoneyOf scalar multiplication in place | 33 | 0 | 1 |
| MoneyOf scalar multiplication near the maximum | 32 | 0 | 1 |
| MoneyOf scalar multiplication, Int32 operand | 41 | 0 | 1 |
| MoneyOf scalar multiplication, Int64 operand | 14 | 0 | 1 |
| MoneyOf scaled and rounded | 238 | 0 | 10 |
| MoneyOf scaled and rounded, large amount | 258 | 0 | 9 |
| MoneyOf subtraction | 9 | 0 | 1 |

### Money (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money addition in place, throwing | 24 | 0 | 1 |
| Money addition, separately built currencies | 25 | 0 | 1 |
| Money addition, throwing | 25 | 0 | 1 |
| Money applying a rate | 61 | 0 | 2 |
| Money description | 393 | 0 | 12 |
| Money equality | 20 | 0 | 1 |
| Money hashing | 215 | 0 | 11 |
| Money init exactly | 28 | 0 | 1 |
| Money is less than, throwing | 20 | 0 | 1 |
| Money is multiple, throwing | 24 | 0 | 1 |
| Money parsing | 354 | 0 | 9 |
| Money parsing, caller's currency | 307 | 0 | 8 |
| Money parsing, whole major units | 351 | 0 | 9 |
| Money proportion, throwing | 248 | 0 | 7 |
| Money scalar multiplication, amount times integer | 32 | 0 | 1 |
| Money scalar multiplication, integer times amount | 32 | 0 | 1 |
| Money subtraction in place, throwing | 14 | 0 | 1 |
| Money subtraction, throwing | 39 | 0 | 1 |

### MoneyOf.Unrounded (typed currency)

A typed row should cost no more than its `Money.Unrounded` twin, which also compares currencies. One that costs more is usually generic code running unspecialized across the module boundary.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf chain, rounding each step | 719 | 0 | 36 |
| MoneyOf unrounded | 26 | 0 | 1 |
| MoneyOf unrounded addition | 37 | 0 | 1 |
| MoneyOf unrounded chain | 1167 | 0 | 66 |
| MoneyOf unrounded converted | 345 | 0 | 15 |
| MoneyOf unrounded divided | 269 | 0 | 10 |
| MoneyOf unrounded divided exactly | 225 | 0 | 7 |
| MoneyOf unrounded from major units | 878 | 0 | 25 |
| MoneyOf unrounded from minor units | 29 | 0 | 1 |
| MoneyOf unrounded minus settled | 39 | 0 | 1 |
| MoneyOf unrounded plus settled | 39 | 0 | 1 |
| MoneyOf unrounded rounded | 231 | 0 | 9 |
| MoneyOf unrounded scaling | 337 | 0 | 14 |
| MoneyOf unrounded subtraction | 37 | 0 | 1 |
| MoneyOf unrounded times an integer | 65 | 0 | 2 |
| MoneyOf unrounded total of 10 | 116 | 0 | 4 |

### Money.Unrounded (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money unrounded addition, throwing | 46 | 0 | 1 |
| Money unrounded applying a rate | 386 | 0 | 13 |
| Money unrounded divided by an integer | 276 | 0 | 10 |
| Money unrounded divided exactly | 229 | 0 | 8 |
| Money unrounded minus settled, throwing | 77 | 0 | 2 |
| Money unrounded plus settled, throwing | 72 | 0 | 2 |
| Money unrounded rounded | 238 | 0 | 9 |
| Money unrounded scaling by a rate | 386 | 0 | 13 |
| Money unrounded scaling by an integer | 69 | 0 | 2 |
| Money unrounded subtraction, throwing | 46 | 0 | 1 |
| Money unrounded total of 10, throwing | 171 | 0 | 5 |

### Rate

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate equality | 19 | 0 | 1 |
| Rate from a decimal string | 754 | 0 | 24 |
| Rate from a Double | 2220 | 0 | 73 |
| Rate from a fraction string | 1724 | 0 | 55 |
| Rate from a large decimal string | 1861 | 0 | 61 |
| Rate from a negative decimal string | 818 | 0 | 26 |
| Rate from a negative fraction string | 2019 | 0 | 65 |
| Rate from a percent string | 1231 | 0 | 38 |
| Rate from a string literal | 698 | 0 | 22 |
| Rate from basis points | 39 | 0 | 1 |
| Rate from percent | 40 | 0 | 1 |
| Rate to basis points, rounded | 250 | 0 | 8 |
| Rate to whole basis points | 163 | 0 | 5 |

### ExchangeRate and Margin

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| ExchangeRate applying a margin | 315 | 0 | 9 |
| ExchangeRate construction | 330 | 0 | 9 |
| ExchangeRate construction, across scales | 330 | 0 | 9 |
| ExchangeRate crossed | 303 | 0 | 9 |
| Margin construction | 44 | 0 | 2 |
| MoneyOf converted | 57 | 0 | 2 |

### UnitPrice

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| UnitPrice total for a fractional quantity | 334 | 0 | 10 |
| UnitPrice total for a whole quantity | 62 | 0 | 2 |

### Currency, CurrencyCode, UnitScale, AnyCurrency

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| AnyCurrency storage for a custom field | 107 | 0 | 4 |
| Currency construction, custom | 109 | 0 | 5 |
| Currency description | 155 | 0 | 6 |
| Currency equality | 26 | 0 | 1 |
| CurrencyCode description | 177 | 0 | 7 |
| CurrencyCode equality | 21 | 0 | 1 |
| CurrencyCode validation | 268 | 0 | 10 |
| CurrencyCode validation, eight characters | 489 | 0 | 18 |
| CurrencyCode validation, lowercase | 266 | 0 | 10 |
| ISO currency lookup | 87 | 0 | 3 |
| UnitScale construction | 68 | 0 | 3 |
| UnitScale from decimal places | 27 | 0 | 1 |

### Splitting: Split, WeightedSplit, Weights, PartCount, Weight

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money split by weights | 4019 | 4 | 132 |
| Money split into 3 | 62 | 0 | 2 |
| MoneyOf split by 10 weights | 5682 | 4 | 190 |
| MoneyOf split by weights | 4007 | 4 | 130 |
| MoneyOf split by weights that divide exactly | 3036 | 3 | 100 |
| MoneyOf split into 1000, materialized | 3983 | 1 | 164 |
| MoneyOf split into 3 | 58 | 0 | 2 |
| MoneyOf split, iterating the parts | 88 | 0 | 4 |
| PartCount construction | 25 | 0 | 1 |
| Split counting the parts | 13 | 0 | 1 |
| Weight construction | 25 | 0 | 1 |
| WeightedSplit amounts | 946 | 1 | 29 |
| WeightedSplit count | 15 | 0 | 1 |
| WeightedSplit weights | 946 | 1 | 29 |
| Weights construction | 777 | 1 | 22 |

### Sequence.total

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money total of 10, throwing | 149 | 0 | 4 |
| MoneyOf total of 10 | 86 | 0 | 3 |
| MoneyOf total of 1000 | 6027 | 0 | 235 |

### Serialization: bytes, Codable, MoneyCodingFormat

The JSON rows are mostly Foundation's coder; the `Control` peer (a plain `Int64` in the same coder) is the floor. The byte serializer is fifteen bytes, allocation-free.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money bytes decode | 212 | 0 | 5 |
| Money bytes encode | 255 | 0 | 10 |
| Money encode, no coder | 795 | 0 | 29 |
| Money encode, no coder, two fields | 4693 | 1 | 156 |
| Money JSON decode | 14K | 6 | 462 |
| Money JSON decode, two fields | 54K | 29 | 1900 |
| Money JSON decode, whole major units | 17K | 7 | 568 |
| Money JSON encode | 6710 | 2 | 241 |
| Money JSON encode, major units | 9571 | 3 | 345 |
| Money JSON encode, two fields | 28K | 11 | 988 |
| Money Unrounded bytes decode | 228 | 0 | 6 |
| MoneyCodingFormat custom fields | 4405 | 2 | 164 |
| MoneyOf bytes decode | 174 | 0 | 4 |
| MoneyOf bytes encode | 266 | 0 | 10 |
| MoneyOf bytes encode, extremes | 266 | 0 | 9 |
| MoneyOf JSON decode, amount only | 19K | 12 | 699 |
| MoneyOf JSON encode, amount only | 10K | 3 | 343 |
| MoneyOf Unrounded bytes decode | 190 | 0 | 5 |
| MoneyOf Unrounded bytes encode | 511 | 0 | 16 |
| MoneyOf unroundedBytes | 514 | 0 | 17 |

### MoneyFormat (Core engine)

The engine alone, rendering with a prebuilt descriptor. The `MoneyOf format` rows under *Outside Core* add building that descriptor from the packed CLDR tables on every call.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Engine format, accounting, en_GB [engine] | 2299 | 0 | 79 |
| Engine format, default, en_GB [engine] | 2230 | 0 | 76 |
| Engine format, grouped, en_GB [engine] | 2674 | 0 | 93 |
| Engine format, precision 1dp, en_GB [engine] | 2146 | 0 | 74 |
| FractionLength construction | 27 | 0 | 1 |

### Peer baselines

`Int`/`Int128` show what type safety costs, `Double` is the fast answer that is wrong at scale, `FixedPointDecimal` is the closest published peer, and `Decimal` is the exact answer that is slow. `Control` is a plain `Int64` through the same JSON coder.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Control JSON decode | 8401 | 6 | 334 |
| Control JSON encode | 5956 | 2 | 279 |
| Decimal addition | 7128 | 6 | 227 |
| Decimal chained scaling | 55K | 41 | 2238 |
| Decimal comparison | 3936 | 4 | 133 |
| Decimal description | 6661 | 3 | 230 |
| Decimal divided by 3 | 50K | 37 | 1675 |
| Decimal from a decimal string | 4667 | 2 | 176 |
| Decimal JSON decode | 12K | 8 | 417 |
| Decimal JSON encode | 11K | 5 | 404 |
| Decimal multiplied by a rate | 13K | 10 | 416 |
| Decimal parsing | 4741 | 2 | 179 |
| Decimal scalar multiplication | 6240 | 5 | 189 |
| Decimal scaled and rounded | 107K | 83 | 3469 |
| Decimal subtraction | 7825 | 7 | 238 |
| Double addition | 6 | 0 | 1 |
| Double chained scaling | 12 | 0 | 1 |
| Double comparison | 15 | 0 | 1 |
| Double description | 526 | 0 | 16 |
| Double divided by 3 | 9 | 0 | 0 |
| Double from a decimal string | 292 | 0 | 10 |
| Double multiplied by a rate | 9 | 0 | 1 |
| Double parsing | 270 | 0 | 8 |
| Double scalar multiplication | 7 | 0 | 1 |
| Double scaled and rounded | 7 | 0 | 1 |
| Double subtraction | 8 | 0 | 1 |
| FixedPoint addition | 13 | 0 | 1 |
| FixedPoint chained scaling | 473 | 0 | 32 |
| FixedPoint comparison | 15 | 0 | 1 |
| FixedPoint scalar multiplication | 150 | 0 | 5 |
| FixedPoint scaled and rounded | 179 | 0 | 8 |
| FixedPoint subtraction | 13 | 0 | 1 |
| Int addition | 9 | 0 | 1 |
| Int chained scaling, truncating | 23 | 0 | 1 |
| Int comparison | 15 | 0 | 1 |
| Int description | 470 | 0 | 15 |
| Int hashing | 152 | 0 | 7 |
| Int parsing | 91 | 0 | 3 |
| Int quotient and remainder | 28 | 0 | 1 |
| Int scalar multiplication | 14 | 0 | 1 |
| Int scaled, truncating | 6 | 0 | 0 |
| Int subtraction | 9 | 0 | 1 |
| Int128 addition | 12 | 0 | 1 |
| Int128 chained scaling, truncating | 108 | 0 | 7 |
| Int128 comparison | 17 | 0 | 1 |
| Int128 scalar multiplication | 29 | 0 | 1 |
| Int128 scaled, truncating | 27 | 0 | 1 |
| Int128 subtraction | 12 | 0 | 1 |

### Outside Core: Foundation and Localization

Not `SwiftMoneyCore`, kept so the whole run is in one place. `[engine]` renders without ICU, `[ICU fallback]` hands the work to Foundation, `[ICU]` is Foundation's own style.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Decimal attributed, default, en_GB [ICU] | 146K | 39 | 6466 |
| Decimal format, default, en_GB [ICU] | 23K | 10 | 820 |
| Decimal format, every option, en_GB [ICU] | 21K | 10 | 751 |
| Decimal format, full name, en_GB [ICU] | 25K | 11 | 892 |
| Decimal format, grouping never, en_GB [ICU] | 41K | 21 | 1419 |
| Decimal format, ISO code, en_GB [ICU] | 23K | 10 | 832 |
| Decimal format, narrow, en_GB [ICU] | 23K | 10 | 828 |
| Decimal format, precision 1dp and accounting, en_GB [ICU] | 25K | 12 | 916 |
| Decimal format, precision 1dp, en_GB [ICU] | 22K | 10 | 830 |
| Decimal format, precision 2dp, en_GB [ICU] | 22K | 10 | 838 |
| Decimal format, separator always, en_GB [ICU] | 24K | 11 | 869 |
| Decimal format, sign accounting, en_GB [ICU] | 26K | 12 | 940 |
| Decimal format, sign always, en_GB [ICU] | 25K | 11 | 916 |
| Decimal format, sign never, en_GB [ICU] | 25K | 11 | 883 |
| Decimal from MoneyOf | 257 | 0 | 9 |
| Decimal parse, en_GB [ICU] | 25K | 8 | 890 |
| Money format, default, en_GB [engine] | 15K | 0 | 583 |
| Money from Decimal | 18K | 11 | 632 |
| Money parse, en_GB [ICU] | 45K | 19 | 1605 |
| MoneyLocalization moneyFormat, en_GB | 8087 | 0 | 325 |
| MoneyLocalization moneyFormat, ISO code, en_GB | 8355 | 0 | 319 |
| MoneyOf attributed, default, en_GB [engine] | 214K | 59 | 9053 |
| MoneyOf format, default, en_GB [engine] | 16K | 0 | 592 |
| MoneyOf format, every option, en_GB [engine] | 16K | 0 | 610 |
| MoneyOf format, full name, en_GB [engine] | 19K | 1 | 674 |
| MoneyOf format, grouping never, en_GB [engine] | 15K | 0 | 562 |
| MoneyOf format, increment, en_GB [ICU fallback] | 30K | 13 | 1049 |
| MoneyOf format, ISO code, en_GB [engine] | 16K | 0 | 581 |
| MoneyOf format, narrow, en_GB [engine] | 15K | 0 | 557 |
| MoneyOf format, precision 1dp and accounting, en_GB [engine] | 16K | 0 | 579 |
| MoneyOf format, precision 1dp, en_GB [engine] | 15K | 0 | 578 |
| MoneyOf format, precision 2dp, en_GB [engine] | 16K | 0 | 590 |
| MoneyOf format, separator always, en_GB [engine] | 15K | 0 | 560 |
| MoneyOf format, sign accounting, en_GB [engine] | 16K | 0 | 590 |
| MoneyOf format, sign always, en_GB [engine] | 15K | 0 | 559 |
| MoneyOf format, sign never, en_GB [engine] | 15K | 0 | 559 |
| MoneyOf from a negative Decimal | 18K | 11 | 575 |
| MoneyOf from Decimal | 18K | 11 | 548 |
| MoneyOf parse, en_GB [ICU] | 46K | 19 | 1645 |

### Harness floor

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 0 |

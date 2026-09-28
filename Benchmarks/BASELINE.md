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
| MoneyOf description, large negative | 1,592 | 1 | 70 |
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
| MoneyOf parsing a negative amount | 204 | 0 | 5 |
| MoneyOf parsing, whole major units | 263 | 0 | 7 |
| MoneyOf proportion | 229 | 0 | 7 |
| MoneyOf proportion of large amounts | 280 | 0 | 12 |
| MoneyOf scalar multiplication | 14 | 0 | 1 |
| MoneyOf scalar multiplication in place | 33 | 0 | 1 |
| MoneyOf scalar multiplication near the maximum | 32 | 0 | 1 |
| MoneyOf scalar multiplication, Int32 operand | 41 | 0 | 1 |
| MoneyOf scalar multiplication, Int64 operand | 14 | 0 | 1 |
| MoneyOf scaled and rounded | 238 | 0 | 9 |
| MoneyOf scaled and rounded, large amount | 258 | 0 | 10 |
| MoneyOf subtraction | 9 | 0 | 1 |

### Money (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money addition in place, throwing | 24 | 0 | 1 |
| Money addition, separately built currencies | 25 | 0 | 1 |
| Money addition, throwing | 25 | 0 | 1 |
| Money applying a rate | 61 | 0 | 2 |
| Money description | 393 | 0 | 13 |
| Money equality | 20 | 0 | 1 |
| Money hashing | 215 | 0 | 11 |
| Money init exactly | 28 | 0 | 1 |
| Money is less than, throwing | 20 | 0 | 1 |
| Money is multiple, throwing | 24 | 0 | 1 |
| Money parsing | 354 | 0 | 9 |
| Money parsing, caller's currency | 307 | 0 | 9 |
| Money parsing, whole major units | 351 | 0 | 9 |
| Money proportion, throwing | 248 | 0 | 8 |
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
| MoneyOf unrounded chain | 1,167 | 0 | 65 |
| MoneyOf unrounded converted | 345 | 0 | 14 |
| MoneyOf unrounded divided | 269 | 0 | 10 |
| MoneyOf unrounded divided exactly | 225 | 0 | 7 |
| MoneyOf unrounded from major units | 878 | 0 | 26 |
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
| Money unrounded divided exactly | 229 | 0 | 7 |
| Money unrounded minus settled, throwing | 77 | 0 | 2 |
| Money unrounded plus settled, throwing | 72 | 0 | 2 |
| Money unrounded rounded | 238 | 0 | 9 |
| Money unrounded scaling by a rate | 386 | 0 | 13 |
| Money unrounded scaling by an integer | 69 | 0 | 2 |
| Money unrounded subtraction, throwing | 46 | 0 | 1 |
| Money unrounded total of 10, throwing | 171 | 0 | 6 |

### Rate

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate equality | 19 | 0 | 1 |
| Rate from a decimal string | 754 | 0 | 24 |
| Rate from a Double | 2,220 | 0 | 72 |
| Rate from a fraction string | 1,725 | 0 | 67 |
| Rate from a large decimal string | 1,862 | 0 | 60 |
| Rate from a negative decimal string | 818 | 0 | 26 |
| Rate from a negative fraction string | 2,020 | 0 | 65 |
| Rate from a percent string | 1,231 | 0 | 40 |
| Rate from a string literal | 698 | 0 | 21 |
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
| UnitPrice total for a fractional quantity | 334 | 0 | 11 |
| UnitPrice total for a whole quantity | 62 | 0 | 2 |

### Currency, CurrencyCode, UnitScale, AnyCurrency

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| AnyCurrency storage for a custom field | 107 | 0 | 4 |
| Currency construction, custom | 109 | 0 | 4 |
| Currency description | 155 | 0 | 6 |
| Currency equality | 26 | 0 | 1 |
| CurrencyCode description | 177 | 0 | 7 |
| CurrencyCode equality | 21 | 0 | 1 |
| CurrencyCode validation | 268 | 0 | 9 |
| CurrencyCode validation, eight characters | 489 | 0 | 15 |
| CurrencyCode validation, lowercase | 266 | 0 | 8 |
| ISO currency lookup | 87 | 0 | 3 |
| UnitScale construction | 68 | 0 | 3 |
| UnitScale from decimal places | 27 | 0 | 1 |

### Splitting: Split, WeightedSplit, Weights, PartCount, Weight

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money split by weights | 4,020 | 4 | 137 |
| Money split into 3 | 62 | 0 | 2 |
| MoneyOf split by 10 weights | 5,683 | 4 | 191 |
| MoneyOf split by weights | 4,007 | 4 | 133 |
| MoneyOf split by weights that divide exactly | 3,036 | 3 | 92 |
| MoneyOf split into 1000, materialized | 3,984 | 1 | 156 |
| MoneyOf split into 3 | 58 | 0 | 2 |
| MoneyOf split, iterating the parts | 88 | 0 | 3 |
| PartCount construction | 25 | 0 | 1 |
| Split counting the parts | 13 | 0 | 1 |
| Weight construction | 25 | 0 | 1 |
| WeightedSplit amounts | 946 | 1 | 30 |
| WeightedSplit count | 15 | 0 | 1 |
| WeightedSplit weights | 946 | 1 | 30 |
| Weights construction | 777 | 1 | 23 |

### Sequence.total

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money total of 10, throwing | 149 | 0 | 4 |
| MoneyOf total of 10 | 86 | 0 | 3 |
| MoneyOf total of 1000 | 6,027 | 0 | 236 |

### Serialization: bytes, Codable, MoneyCodingFormat

The JSON rows are mostly Foundation's coder; the `Control` peer (a plain `Int64` in the same coder) is the floor. The byte serializer is fifteen bytes, allocation-free.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money bytes decode | 212 | 0 | 6 |
| Money bytes encode | 255 | 0 | 10 |
| Money encode, no coder | 795 | 0 | 32 |
| Money encode, no coder, two fields | 4,693 | 1 | 159 |
| Money JSON decode | 13,559 | 6 | 447 |
| Money JSON decode, two fields | 54,020 | 29 | 1931 |
| Money JSON decode, whole major units | 16,870 | 7 | 603 |
| Money JSON encode | 6,710 | 2 | 261 |
| Money JSON encode, major units | 9,570 | 3 | 367 |
| Money JSON encode, two fields | 28,136 | 11 | 1055 |
| Money Unrounded bytes decode | 228 | 0 | 6 |
| MoneyCodingFormat custom fields | 4,454 | 2 | 165 |
| MoneyOf bytes decode | 174 | 0 | 5 |
| MoneyOf bytes encode | 266 | 0 | 10 |
| MoneyOf bytes encode, extremes | 266 | 0 | 9 |
| MoneyOf JSON decode, amount only | 19,295 | 12 | 692 |
| MoneyOf JSON encode, amount only | 10,050 | 3 | 348 |
| MoneyOf Unrounded bytes decode | 190 | 0 | 5 |
| MoneyOf Unrounded bytes encode | 511 | 0 | 16 |
| MoneyOf unroundedBytes | 514 | 0 | 17 |

### MoneyFormat (Core engine)

The engine alone, rendering with a prebuilt descriptor. The `MoneyOf format` rows under *Outside Core* add building that descriptor from the packed CLDR tables on every call.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Engine format, accounting, en_GB [engine] | 2,299 | 0 | 77 |
| Engine format, default, en_GB [engine] | 2,229 | 0 | 78 |
| Engine format, grouped, en_GB [engine] | 2,673 | 0 | 93 |
| Engine format, precision 1dp, en_GB [engine] | 2,146 | 0 | 75 |
| FractionLength construction | 27 | 0 | 1 |

### Peer baselines

`Int`/`Int128` show what type safety costs, `Double` is the fast answer that is wrong at scale, `FixedPointDecimal` is the closest published peer, and `Decimal` is the exact answer that is slow. `Control` is a plain `Int64` through the same JSON coder.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Control JSON decode | 8,391 | 6 | 285 |
| Control JSON encode | 5,946 | 2 | 207 |
| Decimal addition | 7,126 | 6 | 214 |
| Decimal chained scaling | 54,519 | 41 | 1688 |
| Decimal comparison | 3,933 | 4 | 122 |
| Decimal description | 6,655 | 3 | 211 |
| Decimal divided by 3 | 50,220 | 37 | 1558 |
| Decimal from a decimal string | 4,667 | 2 | 170 |
| Decimal JSON decode | 11,553 | 8 | 394 |
| Decimal JSON encode | 10,930 | 5 | 362 |
| Decimal multiplied by a rate | 13,109 | 10 | 403 |
| Decimal parsing | 4,740 | 2 | 170 |
| Decimal scalar multiplication | 6,240 | 5 | 183 |
| Decimal scaled and rounded | 107,388 | 83 | 3343 |
| Decimal subtraction | 7,825 | 7 | 234 |
| Double addition | 6 | 0 | 0 |
| Double chained scaling | 12 | 0 | 1 |
| Double comparison | 15 | 0 | 1 |
| Double description | 526 | 0 | 16 |
| Double divided by 3 | 9 | 0 | 0 |
| Double from a decimal string | 292 | 0 | 9 |
| Double multiplied by a rate | 9 | 0 | 1 |
| Double parsing | 270 | 0 | 7 |
| Double scalar multiplication | 7 | 0 | 0 |
| Double scaled and rounded | 7 | 0 | 1 |
| Double subtraction | 8 | 0 | 1 |
| FixedPoint addition | 13 | 0 | 1 |
| FixedPoint chained scaling | 473 | 0 | 31 |
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
| Decimal attributed, default, en_GB [ICU] | 146,239 | 39 | 5688 |
| Decimal format, default, en_GB [ICU] | 22,505 | 10 | 793 |
| Decimal format, every option, en_GB [ICU] | 20,975 | 10 | 738 |
| Decimal format, full name, en_GB [ICU] | 24,670 | 11 | 847 |
| Decimal format, grouping never, en_GB [ICU] | 41,228 | 21 | 1363 |
| Decimal format, ISO code, en_GB [ICU] | 22,817 | 10 | 783 |
| Decimal format, narrow, en_GB [ICU] | 22,526 | 10 | 793 |
| Decimal format, precision 1dp and accounting, en_GB [ICU] | 25,492 | 12 | 878 |
| Decimal format, precision 1dp, en_GB [ICU] | 22,327 | 10 | 819 |
| Decimal format, precision 2dp, en_GB [ICU] | 22,501 | 10 | 787 |
| Decimal format, separator always, en_GB [ICU] | 23,846 | 11 | 850 |
| Decimal format, sign accounting, en_GB [ICU] | 25,648 | 12 | 903 |
| Decimal format, sign always, en_GB [ICU] | 24,590 | 11 | 864 |
| Decimal format, sign never, en_GB [ICU] | 24,560 | 11 | 857 |
| Decimal from MoneyOf | 257 | 0 | 9 |
| Decimal parse, en_GB [ICU] | 24,875 | 8 | 873 |
| Money format, default, en_GB [engine] | 15,166 | 0 | 581 |
| Money from Decimal | 17,851 | 11 | 634 |
| Money parse, en_GB [ICU] | 44,883 | 19 | 1671 |
| MoneyLocalization moneyFormat, en_GB | 8,091 | 0 | 326 |
| MoneyLocalization moneyFormat, ISO code, en_GB | 8,356 | 0 | 355 |
| MoneyOf attributed, default, en_GB [engine] | 213,318 | 59 | 9269 |
| MoneyOf format, default, en_GB [engine] | 15,293 | 0 | 573 |
| MoneyOf format, every option, en_GB [engine] | 16,228 | 0 | 631 |
| MoneyOf format, full name, en_GB [engine] | 18,807 | 1 | 674 |
| MoneyOf format, grouping never, en_GB [engine] | 15,443 | 0 | 582 |
| MoneyOf format, increment, en_GB [ICU fallback] | 29,798 | 13 | 1080 |
| MoneyOf format, ISO code, en_GB [engine] | 15,725 | 0 | 603 |
| MoneyOf format, narrow, en_GB [engine] | 15,332 | 0 | 582 |
| MoneyOf format, precision 1dp and accounting, en_GB [engine] | 15,955 | 0 | 603 |
| MoneyOf format, precision 1dp, en_GB [engine] | 15,535 | 0 | 577 |
| MoneyOf format, precision 2dp, en_GB [engine] | 15,501 | 0 | 578 |
| MoneyOf format, separator always, en_GB [engine] | 15,266 | 0 | 560 |
| MoneyOf format, sign accounting, en_GB [engine] | 15,516 | 0 | 558 |
| MoneyOf format, sign always, en_GB [engine] | 15,434 | 0 | 556 |
| MoneyOf format, sign never, en_GB [engine] | 15,218 | 0 | 560 |
| MoneyOf from a negative Decimal | 18,498 | 11 | 578 |
| MoneyOf from Decimal | 17,836 | 11 | 565 |
| MoneyOf parse, en_GB [ICU] | 45,959 | 19 | 1619 |

### Harness floor

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 0 |

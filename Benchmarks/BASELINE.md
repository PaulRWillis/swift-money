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
| Scale by a rate and round | 2506 | 119 | 179 |
| Chained scaling (three rates) | 7454 | 361 | 473 |

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
| MoneyOf currency | 8 | 0 | 1 |
| MoneyOf description | 394 | 0 | 12 |
| MoneyOf description, large negative | 1,583 | 1 | 73 |
| MoneyOf equality | 7 | 0 | 1 |
| MoneyOf hashing | 152 | 0 | 7 |
| MoneyOf init exactly | 25 | 0 | 1 |
| MoneyOf init major units | 41 | 0 | 1 |
| MoneyOf init major units, Int64 | 41 | 0 | 1 |
| MoneyOf init major units, UInt32 | 41 | 0 | 1 |
| MoneyOf is multiple | 16 | 0 | 1 |
| MoneyOf is negative | 10 | 0 | 1 |
| MoneyOf is positive | 7 | 0 | 0 |
| MoneyOf is zero | 7 | 0 | 0 |
| MoneyOf magnitude | 30 | 0 | 1 |
| MoneyOf negation | 29 | 0 | 1 |
| MoneyOf parsing | 223 | 0 | 6 |
| MoneyOf parsing a large amount | 657 | 0 | 17 |
| MoneyOf parsing a negative amount | 200 | 0 | 6 |
| MoneyOf parsing, whole major units | 257 | 0 | 7 |
| MoneyOf proportion | 158 | 0 | 5 |
| MoneyOf proportion of large amounts | 184 | 0 | 7 |
| MoneyOf scalar multiplication | 14 | 0 | 1 |
| MoneyOf scalar multiplication in place | 33 | 0 | 1 |
| MoneyOf scalar multiplication near the maximum | 32 | 0 | 1 |
| MoneyOf scalar multiplication, Int32 operand | 41 | 0 | 1 |
| MoneyOf scalar multiplication, Int64 operand | 14 | 0 | 1 |
| MoneyOf scaled and rounded | 119 | 0 | 5 |
| MoneyOf scaled and rounded, large amount | 136 | 0 | 5 |
| MoneyOf subtraction | 9 | 0 | 1 |

### Money (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money addition in place, throwing | 23 | 0 | 1 |
| Money addition, separately built currencies | 25 | 0 | 1 |
| Money addition, throwing | 24 | 0 | 1 |
| Money applying a rate | 59 | 0 | 2 |
| Money description | 384 | 0 | 12 |
| Money equality | 15 | 0 | 1 |
| Money hashing | 195 | 0 | 10 |
| Money init exactly | 26 | 0 | 1 |
| Money init major units | 46 | 0 | 1 |
| Money init major units, Int64 | 46 | 0 | 1 |
| Money init major units, UInt32 | 46 | 0 | 1 |
| Money is less than, throwing | 18 | 0 | 1 |
| Money is multiple, throwing | 20 | 0 | 1 |
| Money parsing | 349 | 0 | 9 |
| Money parsing, caller's currency | 301 | 0 | 8 |
| Money parsing, whole major units | 347 | 0 | 9 |
| Money proportion, throwing | 169 | 0 | 5 |
| Money scalar multiplication, amount times integer | 31 | 0 | 1 |
| Money scalar multiplication, integer times amount | 31 | 0 | 1 |
| Money subtraction in place, throwing | 12 | 0 | 1 |
| Money subtraction, throwing | 34 | 0 | 1 |

### MoneyOf.Unrounded (typed currency)

A typed row should cost no more than its `Money.Unrounded` twin, which also compares currencies. One that costs more is usually generic code running unspecialized across the module boundary.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf chain, rounding each step | 361 | 0 | 19 |
| MoneyOf unrounded | 26 | 0 | 1 |
| MoneyOf unrounded addition | 37 | 0 | 1 |
| MoneyOf unrounded chain | 745 | 0 | 33 |
| MoneyOf unrounded converted | 249 | 0 | 9 |
| MoneyOf unrounded divided | 171 | 0 | 8 |
| MoneyOf unrounded divided exactly | 151 | 0 | 5 |
| MoneyOf unrounded from major units | 819 | 0 | 24 |
| MoneyOf unrounded from minor units | 29 | 0 | 1 |
| MoneyOf unrounded minus settled | 39 | 0 | 1 |
| MoneyOf unrounded plus settled | 39 | 0 | 1 |
| MoneyOf unrounded rounded | 109 | 0 | 4 |
| MoneyOf unrounded scaling | 235 | 0 | 6 |
| MoneyOf unrounded subtraction | 37 | 0 | 1 |
| MoneyOf unrounded times an integer | 65 | 0 | 2 |
| MoneyOf unrounded total of 10 | 116 | 0 | 4 |

### Money.Unrounded (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money unrounded addition, throwing | 42 | 0 | 1 |
| Money unrounded applying a rate | 246 | 0 | 7 |
| Money unrounded divided by an integer | 175 | 0 | 6 |
| Money unrounded divided exactly | 153 | 0 | 5 |
| Money unrounded minus settled, throwing | 61 | 0 | 2 |
| Money unrounded plus settled, throwing | 57 | 0 | 2 |
| Money unrounded rounded | 110 | 0 | 4 |
| Money unrounded scaling by a rate | 246 | 0 | 7 |
| Money unrounded scaling by an integer | 67 | 0 | 2 |
| Money unrounded subtraction, throwing | 42 | 0 | 1 |
| Money unrounded total of 10, throwing | 151 | 0 | 5 |

### Rate

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate equality | 19 | 0 | 1 |
| Rate from a decimal string | 726 | 0 | 23 |
| Rate from a Double | 2,132 | 0 | 70 |
| Rate from a fraction string | 1,681 | 0 | 55 |
| Rate from a large decimal string | 1,834 | 0 | 60 |
| Rate from a negative decimal string | 790 | 0 | 26 |
| Rate from a negative fraction string | 1,976 | 0 | 68 |
| Rate from a percent string | 1,203 | 0 | 38 |
| Rate from a string literal | 639 | 0 | 19 |
| Rate from basis points | 39 | 0 | 1 |
| Rate from percent | 40 | 0 | 1 |
| Rate to basis points, rounded | 110 | 0 | 4 |
| Rate to whole basis points | 110 | 0 | 3 |

### ExchangeRate and Margin

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| ExchangeRate applying a margin | 252 | 0 | 7 |
| ExchangeRate construction | 264 | 0 | 8 |
| ExchangeRate construction, across scales | 264 | 0 | 8 |
| ExchangeRate crossed | 240 | 0 | 7 |
| Margin construction | 44 | 0 | 2 |
| MoneyOf converted | 57 | 0 | 2 |

### UnitPrice

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| UnitPrice total for a fractional quantity | 234 | 0 | 7 |
| UnitPrice total for a whole quantity | 62 | 0 | 2 |

### Currency, CurrencyCode, UnitScale, AnyCurrency

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| AnyCurrency storage for a custom field | 103 | 0 | 4 |
| Currency construction, custom | 104 | 0 | 4 |
| Currency description | 149 | 0 | 5 |
| Currency equality | 16 | 0 | 1 |
| CurrencyCode description | 177 | 0 | 7 |
| CurrencyCode equality | 21 | 0 | 1 |
| CurrencyCode validation | 268 | 0 | 9 |
| CurrencyCode validation, eight characters | 489 | 0 | 15 |
| CurrencyCode validation, lowercase | 266 | 0 | 8 |
| ISO currency lookup | 83 | 0 | 3 |
| UnitScale construction | 68 | 0 | 3 |
| UnitScale from decimal places | 27 | 0 | 1 |

### Splitting: Split, WeightedSplit, Weights, PartCount, Weight

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money split by weights | 4,018 | 4 | 133 |
| Money split into 1000, materialized | 6,188 | 1 | 248 |
| Money split into 3 | 63 | 0 | 2 |
| MoneyOf split by 10 weights | 5,682 | 4 | 191 |
| MoneyOf split by weights | 4,007 | 4 | 132 |
| MoneyOf split by weights that divide exactly | 3,036 | 3 | 98 |
| MoneyOf split into 1000, materialized | 3,983 | 1 | 158 |
| MoneyOf split into 3 | 58 | 0 | 2 |
| MoneyOf split, iterating the parts | 88 | 0 | 4 |
| PartCount construction | 25 | 0 | 1 |
| Split counting the parts | 13 | 0 | 1 |
| Weight construction | 25 | 0 | 1 |
| WeightedSplit amounts | 946 | 1 | 30 |
| WeightedSplit count | 15 | 0 | 1 |
| WeightedSplit weights | 946 | 1 | 29 |
| Weights construction | 777 | 1 | 23 |

### Sequence.total

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money total of 10, throwing | 129 | 0 | 4 |
| Money total of 1000, throwing | 11,022 | 0 | 328 |
| MoneyOf total of 10 | 86 | 0 | 4 |
| MoneyOf total of 1000 | 6,027 | 0 | 235 |

### Serialization: bytes, Codable, MoneyCodingFormat

The JSON rows are mostly Foundation's coder; the `Control` peer (a plain `Int64` in the same coder) is the floor. The byte serializer is fifteen bytes, allocation-free.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money bytes decode | 210 | 0 | 6 |
| Money bytes encode | 255 | 0 | 10 |
| Money encode, no coder | 786 | 0 | 31 |
| Money encode, no coder, two fields | 4,680 | 1 | 153 |
| Money JSON decode | 13,551 | 6 | 446 |
| Money JSON decode, two fields | 54,029 | 29 | 1915 |
| Money JSON decode, whole major units | 16,991 | 7 | 577 |
| Money JSON encode | 6,707 | 2 | 247 |
| Money JSON encode, major units | 9,563 | 3 | 380 |
| Money JSON encode, two fields | 28,313 | 11 | 1198 |
| Money Unrounded bytes decode | 226 | 0 | 6 |
| MoneyCodingFormat custom fields | 4,467 | 2 | 166 |
| MoneyOf bytes decode | 170 | 0 | 4 |
| MoneyOf bytes encode | 266 | 0 | 9 |
| MoneyOf bytes encode, extremes | 266 | 0 | 8 |
| MoneyOf JSON decode, amount only | 19,143 | 12 | 663 |
| MoneyOf JSON encode, amount only | 10,048 | 3 | 359 |
| MoneyOf Unrounded bytes decode | 187 | 0 | 5 |
| MoneyOf Unrounded bytes encode | 511 | 0 | 16 |
| MoneyOf unroundedBytes | 514 | 0 | 17 |

### MoneyFormat (Core engine)

The engine alone, rendering with a prebuilt descriptor. The `MoneyOf format` rows under *Outside Core* add building that descriptor from the packed CLDR tables on every call.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Engine format, accounting, en_GB [engine] | 2,170 | 0 | 71 |
| Engine format, default, en_GB [engine] | 1,971 | 0 | 67 |
| Engine format, grouped, en_GB [engine] | 2,411 | 0 | 81 |
| Engine format, precision 1dp, en_GB [engine] | 1,988 | 0 | 71 |
| FractionLength construction | 27 | 0 | 1 |

### Peer baselines

`Int`/`Int128` show what type safety costs, `Double` is the fast answer that is wrong at scale, `FixedPointDecimal` is the closest published peer, and `Decimal` is the exact answer that is slow. `Control` is a plain `Int64` through the same JSON coder.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Control JSON decode | 8,391 | 6 | 279 |
| Control JSON encode | 5,948 | 2 | 222 |
| Decimal addition | 7,126 | 6 | 223 |
| Decimal chained scaling | 54,593 | 41 | 1961 |
| Decimal comparison | 3,934 | 4 | 129 |
| Decimal description | 6,656 | 3 | 219 |
| Decimal divided by 3 | 50,227 | 37 | 1583 |
| Decimal from a decimal string | 4,667 | 2 | 166 |
| Decimal JSON decode | 11,555 | 8 | 387 |
| Decimal JSON encode | 10,931 | 5 | 362 |
| Decimal multiplied by a rate | 13,110 | 10 | 421 |
| Decimal parsing | 4,740 | 2 | 174 |
| Decimal scalar multiplication | 6,241 | 5 | 186 |
| Decimal scaled and rounded | 107,387 | 83 | 3861 |
| Decimal subtraction | 7,825 | 7 | 252 |
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
| FixedPoint chained scaling | 473 | 0 | 30 |
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
| Int128 chained scaling, truncating | 108 | 0 | 6 |
| Int128 comparison | 17 | 0 | 1 |
| Int128 scalar multiplication | 29 | 0 | 1 |
| Int128 scaled, truncating | 27 | 0 | 1 |
| Int128 subtraction | 12 | 0 | 1 |

### Outside Core: Foundation and Localization

Not `SwiftMoneyCore`, kept so the whole run is in one place. `[engine]` renders without ICU, `[ICU fallback]` hands the work to Foundation, `[ICU]` is Foundation's own style.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Decimal attributed, default, en_GB [ICU] | 146,164 | 39 | 5758 |
| Decimal format, default, en_GB [ICU] | 22,500 | 10 | 781 |
| Decimal format, every option, en_GB [ICU] | 20,977 | 10 | 730 |
| Decimal format, full name, en_GB [ICU] | 24,672 | 11 | 865 |
| Decimal format, grouping never, en_GB [ICU] | 41,232 | 21 | 1401 |
| Decimal format, ISO code, en_GB [ICU] | 22,817 | 10 | 803 |
| Decimal format, narrow, en_GB [ICU] | 22,528 | 10 | 777 |
| Decimal format, precision 1dp and accounting, en_GB [ICU] | 25,498 | 12 | 945 |
| Decimal format, precision 1dp, en_GB [ICU] | 22,328 | 10 | 764 |
| Decimal format, precision 2dp, en_GB [ICU] | 22,500 | 10 | 778 |
| Decimal format, separator always, en_GB [ICU] | 23,878 | 11 | 1621 |
| Decimal format, sign accounting, en_GB [ICU] | 25,652 | 12 | 919 |
| Decimal format, sign always, en_GB [ICU] | 24,590 | 11 | 848 |
| Decimal format, sign never, en_GB [ICU] | 24,564 | 11 | 919 |
| Decimal from MoneyOf | 257 | 0 | 9 |
| Decimal parse, en_GB [ICU] | 24,874 | 8 | 872 |
| Money format, default, en_GB [engine] | 14,663 | 0 | 553 |
| Money from Decimal | 17,837 | 11 | 573 |
| Money parse, en_GB [ICU] | 44,883 | 19 | 1621 |
| MoneyLocalization moneyFormat, en_GB | 8,086 | 0 | 339 |
| MoneyLocalization moneyFormat, ISO code, en_GB | 8,359 | 0 | 323 |
| MoneyOf attributed, default, en_GB [engine] | 213,000 | 59 | 9367 |
| MoneyOf format, default, en_GB [engine] | 14,705 | 0 | 547 |
| MoneyOf format, every option, en_GB [engine] | 16,265 | 0 | 642 |
| MoneyOf format, full name, en_GB [engine] | 17,997 | 1 | 679 |
| MoneyOf format, grouping never, en_GB [engine] | 14,798 | 0 | 568 |
| MoneyOf format, increment, en_GB [ICU fallback] | 29,594 | 13 | 1060 |
| MoneyOf format, ISO code, en_GB [engine] | 15,166 | 0 | 568 |
| MoneyOf format, narrow, en_GB [engine] | 14,730 | 0 | 564 |
| MoneyOf format, precision 1dp and accounting, en_GB [engine] | 15,256 | 0 | 589 |
| MoneyOf format, precision 1dp, en_GB [engine] | 14,948 | 0 | 565 |
| MoneyOf format, precision 2dp, en_GB [engine] | 14,982 | 0 | 570 |
| MoneyOf format, separator always, en_GB [engine] | 14,739 | 0 | 608 |
| MoneyOf format, sign accounting, en_GB [engine] | 14,959 | 0 | 596 |
| MoneyOf format, sign always, en_GB [engine] | 14,707 | 0 | 575 |
| MoneyOf format, sign never, en_GB [engine] | 14,747 | 0 | 564 |
| MoneyOf from a negative Decimal | 18,499 | 11 | 602 |
| MoneyOf from Decimal | 17,835 | 11 | 567 |
| MoneyOf parse, en_GB [ICU] | 45,954 | 19 | 1665 |

### Harness floor

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 1 |

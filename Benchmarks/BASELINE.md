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
| Chained scaling (three rates) | 7454 | 361 | 475 |

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
| MoneyOf description | 403 | 0 | 13 |
| MoneyOf description, large negative | 1,593 | 1 | 72 |
| MoneyOf equality | 7 | 0 | 1 |
| MoneyOf from Money, throwing | 35 | 0 | 1 |
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
| MoneyOf parsing | 227 | 0 | 6 |
| MoneyOf parsing a large amount | 662 | 0 | 17 |
| MoneyOf parsing a negative amount | 204 | 0 | 6 |
| MoneyOf parsing, whole major units | 263 | 0 | 7 |
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
| Money addition in place, throwing | 24 | 0 | 1 |
| Money addition, separately built currencies | 25 | 0 | 1 |
| Money addition, throwing | 25 | 0 | 1 |
| Money applying a rate | 61 | 0 | 2 |
| Money description | 393 | 0 | 12 |
| Money equality | 20 | 0 | 1 |
| Money from MoneyOf | 31 | 0 | 1 |
| Money hashing | 215 | 0 | 11 |
| Money init exactly | 28 | 0 | 1 |
| Money init major units | 46 | 0 | 1 |
| Money init major units, Int64 | 46 | 0 | 1 |
| Money init major units, UInt32 | 46 | 0 | 1 |
| Money is less than, throwing | 20 | 0 | 1 |
| Money is multiple, throwing | 24 | 0 | 1 |
| Money parsing | 354 | 0 | 9 |
| Money parsing, caller's currency | 307 | 0 | 8 |
| Money parsing, whole major units | 351 | 0 | 9 |
| Money proportion, throwing | 183 | 0 | 6 |
| Money scalar multiplication, amount times integer | 32 | 0 | 1 |
| Money scalar multiplication, integer times amount | 32 | 0 | 1 |
| Money subtraction in place, throwing | 14 | 0 | 1 |
| Money subtraction, throwing | 39 | 0 | 1 |

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
| MoneyOf unrounded from major units | 819 | 0 | 25 |
| MoneyOf unrounded from minor units | 29 | 0 | 1 |
| MoneyOf unrounded minus settled | 39 | 0 | 1 |
| MoneyOf unrounded plus settled | 39 | 0 | 1 |
| MoneyOf unrounded rounded | 109 | 0 | 4 |
| MoneyOf unrounded scaling | 235 | 0 | 7 |
| MoneyOf unrounded subtraction | 37 | 0 | 1 |
| MoneyOf unrounded times an integer | 65 | 0 | 2 |
| MoneyOf unrounded total of 10 | 116 | 0 | 4 |

### Money.Unrounded (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money unrounded addition, throwing | 46 | 0 | 1 |
| Money unrounded applying a rate | 249 | 0 | 7 |
| Money unrounded divided by an integer | 177 | 0 | 7 |
| Money unrounded divided exactly | 155 | 0 | 5 |
| Money unrounded minus settled, throwing | 77 | 0 | 2 |
| Money unrounded plus settled, throwing | 72 | 0 | 2 |
| Money unrounded rounded | 112 | 0 | 4 |
| Money unrounded scaling by a rate | 249 | 0 | 7 |
| Money unrounded scaling by an integer | 69 | 0 | 2 |
| Money unrounded subtraction, throwing | 46 | 0 | 1 |
| Money unrounded total of 10, throwing | 171 | 0 | 5 |

### Rate

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate equality | 19 | 0 | 1 |
| Rate from a decimal string | 726 | 0 | 24 |
| Rate from a Double | 2,132 | 0 | 73 |
| Rate from a fraction string | 1,682 | 0 | 57 |
| Rate from a large decimal string | 1,836 | 0 | 67 |
| Rate from a negative decimal string | 791 | 0 | 29 |
| Rate from a negative fraction string | 1,977 | 0 | 66 |
| Rate from a percent string | 1,203 | 0 | 39 |
| Rate from a string literal | 640 | 0 | 21 |
| Rate from basis points | 39 | 0 | 1 |
| Rate from percent | 40 | 0 | 1 |
| Rate to basis points, rounded | 110 | 0 | 4 |
| Rate to whole basis points | 110 | 0 | 4 |

### ExchangeRate and Margin

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| ExchangeRate applying a margin | 252 | 0 | 7 |
| ExchangeRate construction | 268 | 0 | 8 |
| ExchangeRate construction, across scales | 268 | 0 | 8 |
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
| AnyCurrency storage for a custom field | 107 | 0 | 4 |
| Currency construction, custom | 109 | 0 | 4 |
| Currency description | 155 | 0 | 5 |
| Currency equality | 26 | 0 | 1 |
| CurrencyCode description | 177 | 0 | 8 |
| CurrencyCode equality | 21 | 0 | 1 |
| CurrencyCode validation | 268 | 0 | 9 |
| CurrencyCode validation, eight characters | 489 | 0 | 14 |
| CurrencyCode validation, lowercase | 266 | 0 | 9 |
| ISO currency lookup | 87 | 0 | 3 |
| UnitScale construction | 68 | 0 | 3 |
| UnitScale from decimal places | 27 | 0 | 1 |

### Splitting: Split, WeightedSplit, Weights, PartCount, Weight

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money split by weights | 4,020 | 4 | 132 |
| Money split into 3 | 62 | 0 | 2 |
| MoneyOf split by 10 weights | 5,683 | 4 | 196 |
| MoneyOf split by weights | 4,007 | 4 | 131 |
| MoneyOf split by weights that divide exactly | 3,037 | 3 | 97 |
| MoneyOf split into 1000, materialized | 3,985 | 1 | 169 |
| MoneyOf split into 3 | 58 | 0 | 2 |
| MoneyOf split, iterating the parts | 88 | 0 | 4 |
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
| MoneyOf total of 10 | 86 | 0 | 4 |
| MoneyOf total of 1000 | 6,029 | 0 | 245 |

### Ranges and steps

A typed row should cost no more than its runtime twin, which also compares currencies. The `ClosedRange of MoneyOf` rows exercise only the standard library, the floor the runtime ranges are measured against.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| ClosedMoneyRange clamped, throwing | 57 | 0 | 3 |
| ClosedMoneyRange construction, throwing | 57 | 0 | 2 |
| ClosedMoneyRange contains a closed range, throwing | 23 | 0 | 1 |
| ClosedMoneyRange contains a half-open range, throwing | 53 | 0 | 2 |
| ClosedMoneyRange contains, throwing | 24 | 0 | 1 |
| ClosedMoneyRange debug description | 4,102 | 3 | 154 |
| ClosedMoneyRange description | 2,026 | 1 | 73 |
| ClosedMoneyRange from a half-open range | 41 | 0 | 1 |
| ClosedMoneyRange from a typed range | 20 | 0 | 1 |
| ClosedMoneyRange from checked bounds, throwing | 57 | 0 | 2 |
| ClosedMoneyRange overlaps a half-open range, throwing | 51 | 0 | 2 |
| ClosedMoneyRange overlaps, throwing | 23 | 0 | 1 |
| ClosedMoneyRange steps, throwing | 103 | 0 | 4 |
| ClosedRange from a half-open range | 38 | 0 | 1 |
| ClosedRange from checked bounds, throwing | 33 | 0 | 1 |
| ClosedRange from ClosedMoneyRange, throwing | 38 | 0 | 1 |
| ClosedRange of MoneyOf clamped | 43 | 0 | 1 |
| ClosedRange of MoneyOf construction | 33 | 0 | 2 |
| ClosedRange of MoneyOf contains | 16 | 0 | 1 |
| ClosedRange of MoneyOf contains a closed range | 16 | 0 | 1 |
| ClosedRange of MoneyOf overlaps | 16 | 0 | 1 |
| ClosedRange of MoneyOf steps, throwing | 56 | 0 | 2 |
| Money clamped to a closed range, throwing | 41 | 0 | 1 |
| Money clamped to a lower bound, throwing | 37 | 0 | 1 |
| Money clamped to an upper bound, throwing | 37 | 0 | 1 |
| Money.Steps contains | 44 | 0 | 2 |
| Money.Steps firstIndex of | 172 | 0 | 8 |
| Money.Steps from bounds and step, throwing | 93 | 0 | 2 |
| Money.Steps from typed steps | 35 | 0 | 1 |
| Money.Steps index for an amount, rounding down, throwing | 93 | 0 | 3 |
| Money.Steps index for an amount, throwing | 102 | 0 | 4 |
| Money.Steps index offset by, limited by | 39 | 0 | 1 |
| Money.Steps lastIndex of | 63 | 0 | 2 |
| Money.Steps subscript | 49 | 0 | 1 |
| Money.Steps walk, £250 by £25 | 71 | 0 | 2 |
| Money.Stride from a typed stride | 31 | 0 | 1 |
| Money.Stride init exactly | 36 | 0 | 1 |
| Money.Stride major unit of a currency | 42 | 0 | 1 |
| Money.Stride major unit of an amount | 42 | 0 | 1 |
| Money.Stride major units of a currency | 50 | 0 | 2 |
| Money.Stride major units of an amount | 51 | 0 | 2 |
| Money.Stride minor unit of a currency | 31 | 0 | 1 |
| Money.Stride minor unit of an amount | 31 | 0 | 1 |
| Money.Stride minor units of a currency | 31 | 0 | 1 |
| Money.Stride minor units of an amount | 31 | 0 | 1 |
| MoneyOf clamped to a closed range | 32 | 0 | 1 |
| MoneyOf clamped to a lower bound | 30 | 0 | 1 |
| MoneyOf clamped to an upper bound | 30 | 0 | 1 |
| MoneyOf.Steps contains | 36 | 0 | 1 |
| MoneyOf.Steps firstIndex of | 156 | 0 | 7 |
| MoneyOf.Steps from bounds and step, throwing | 63 | 0 | 2 |
| MoneyOf.Steps from runtime steps, throwing | 38 | 0 | 1 |
| MoneyOf.Steps index for an amount | 82 | 0 | 3 |
| MoneyOf.Steps index for an amount, rounding down | 74 | 0 | 3 |
| MoneyOf.Steps index offset by, limited by | 39 | 0 | 1 |
| MoneyOf.Steps lastIndex of | 53 | 0 | 2 |
| MoneyOf.Steps subscript | 47 | 0 | 1 |
| MoneyOf.Steps walk, £250 by £25 | 65 | 0 | 2 |
| MoneyOf.Stride from a runtime stride, throwing | 35 | 0 | 1 |
| MoneyOf.Stride init exactly | 31 | 0 | 1 |
| MoneyOf.Stride major unit | 33 | 0 | 1 |
| MoneyOf.Stride major units | 37 | 0 | 2 |
| MoneyOf.Stride minor unit | 22 | 0 | 1 |
| MoneyOf.Stride minor units | 22 | 0 | 1 |
| MoneyRange clamped, throwing | 57 | 0 | 3 |
| MoneyRange construction, throwing | 62 | 0 | 2 |
| MoneyRange contains a closed range, throwing | 26 | 0 | 1 |
| MoneyRange contains a half-open range, throwing | 49 | 0 | 4 |
| MoneyRange contains, throwing | 24 | 0 | 1 |
| MoneyRange debug description | 4,058 | 3 | 150 |
| MoneyRange description | 2,026 | 1 | 72 |
| MoneyRange from a closed range | 40 | 0 | 1 |
| MoneyRange from a typed range | 20 | 0 | 1 |
| MoneyRange from checked bounds, throwing | 62 | 0 | 2 |
| MoneyRange is empty | 8 | 0 | 0 |
| MoneyRange overlaps a closed range, throwing | 51 | 0 | 1 |
| MoneyRange overlaps, throwing | 50 | 0 | 4 |
| PartialMoneyRangeFrom construction | 16 | 0 | 1 |
| PartialMoneyRangeFrom contains, throwing | 25 | 0 | 1 |
| PartialMoneyRangeThrough construction | 16 | 0 | 1 |
| PartialMoneyRangeThrough contains, throwing | 25 | 0 | 1 |
| PartialMoneyRangeUpTo construction | 16 | 0 | 1 |
| PartialMoneyRangeUpTo contains, throwing | 25 | 0 | 1 |
| PartialRangeUpTo of MoneyOf construction | 28 | 0 | 1 |
| PartialRangeUpTo of MoneyOf contains | 12 | 0 | 1 |
| Range from a closed range | 37 | 0 | 1 |
| Range from checked bounds, throwing | 33 | 0 | 1 |
| Range from MoneyRange, throwing | 38 | 0 | 1 |
| Range of MoneyOf construction | 33 | 0 | 1 |
| Range of MoneyOf contains | 16 | 0 | 1 |
| stride through Int64, £250 by £25 | 96 | 0 | 4 |
| stride through Money, £250 by £25, throwing | 190 | 0 | 7 |
| stride through MoneyOf, £250 by £25 | 159 | 0 | 6 |
| stride to Money, £250 by £25, throwing | 182 | 0 | 7 |
| stride to MoneyOf, £250 by £25 | 162 | 0 | 6 |

### Serialization: bytes, Codable, MoneyCodingFormat

The JSON rows are mostly Foundation's coder; the `Control` peer (a plain `Int64` in the same coder) is the floor. The byte serializer is fifteen bytes, allocation-free.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money bytes decode | 212 | 0 | 6 |
| Money bytes encode | 255 | 0 | 10 |
| Money encode, no coder | 795 | 0 | 32 |
| Money encode, no coder, two fields | 4,696 | 1 | 150 |
| Money JSON decode | 13,474 | 6 | 483 |
| Money JSON decode, two fields | 54,009 | 29 | 1962 |
| Money JSON decode, whole major units | 16,995 | 7 | 593 |
| Money JSON encode | 6,712 | 2 | 247 |
| Money JSON encode, major units | 9,571 | 3 | 355 |
| Money JSON encode, two fields | 28,143 | 11 | 1056 |
| Money Unrounded bytes decode | 228 | 0 | 6 |
| MoneyCodingFormat custom fields | 4,391 | 2 | 157 |
| MoneyOf bytes decode | 174 | 0 | 5 |
| MoneyOf bytes encode | 266 | 0 | 9 |
| MoneyOf bytes encode, extremes | 266 | 0 | 9 |
| MoneyOf JSON decode, amount only | 19,166 | 12 | 703 |
| MoneyOf JSON encode, amount only | 10,051 | 3 | 359 |
| MoneyOf Unrounded bytes decode | 190 | 0 | 5 |
| MoneyOf Unrounded bytes encode | 511 | 0 | 16 |
| MoneyOf unroundedBytes | 514 | 0 | 17 |

### MoneyFormat (Core engine)

The engine alone, rendering with a prebuilt descriptor. The `MoneyOf format` rows under *Outside Core* add building that descriptor from the packed CLDR tables on every call.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Engine format, accounting, en_GB [engine] | 2,177 | 0 | 83 |
| Engine format, default, en_GB [engine] | 1,976 | 0 | 73 |
| Engine format, grouped, en_GB [engine] | 2,412 | 0 | 87 |
| Engine format, precision 1dp, en_GB [engine] | 1,988 | 0 | 71 |
| FractionLength construction | 27 | 0 | 1 |

### Peer baselines

`Int`/`Int128` show what type safety costs, `Double` is the fast answer that is wrong at scale, `FixedPointDecimal` is the closest published peer, and `Decimal` is the exact answer that is slow. `Control` is a plain `Int64` through the same JSON coder.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Control JSON decode | 8,393 | 6 | 299 |
| Control JSON encode | 5,948 | 2 | 219 |
| Decimal addition | 7,135 | 6 | 262 |
| Decimal chained scaling | 54,528 | 41 | 1810 |
| Decimal comparison | 3,934 | 4 | 128 |
| Decimal description | 6,656 | 3 | 226 |
| Decimal divided by 3 | 50,224 | 37 | 1652 |
| Decimal from a decimal string | 4,668 | 2 | 177 |
| Decimal JSON decode | 11,568 | 8 | 801 |
| Decimal JSON encode | 10,945 | 5 | 770 |
| Decimal multiplied by a rate | 13,116 | 10 | 433 |
| Decimal parsing | 4,765 | 2 | 219 |
| Decimal scalar multiplication | 6,258 | 5 | 222 |
| Decimal scaled and rounded | 107,570 | 83 | 3749 |
| Decimal subtraction | 7,839 | 7 | 261 |
| Double addition | 6 | 0 | 1 |
| Double chained scaling | 12 | 0 | 1 |
| Double comparison | 15 | 0 | 1 |
| Double description | 526 | 0 | 18 |
| Double divided by 3 | 9 | 0 | 0 |
| Double from a decimal string | 292 | 0 | 11 |
| Double multiplied by a rate | 9 | 0 | 1 |
| Double parsing | 270 | 0 | 8 |
| Double scalar multiplication | 7 | 0 | 1 |
| Double scaled and rounded | 7 | 0 | 1 |
| Double subtraction | 8 | 0 | 1 |
| FixedPoint addition | 13 | 0 | 1 |
| FixedPoint chained scaling | 475 | 0 | 33 |
| FixedPoint comparison | 15 | 0 | 1 |
| FixedPoint scalar multiplication | 150 | 0 | 5 |
| FixedPoint scaled and rounded | 179 | 0 | 9 |
| FixedPoint subtraction | 13 | 0 | 1 |
| Int addition | 9 | 0 | 1 |
| Int chained scaling, truncating | 23 | 0 | 1 |
| Int comparison | 15 | 0 | 1 |
| Int description | 470 | 0 | 18 |
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
| Decimal attributed, default, en_GB [ICU] | 146,198 | 39 | 6355 |
| Decimal format, default, en_GB [ICU] | 22,503 | 10 | 827 |
| Decimal format, every option, en_GB [ICU] | 20,981 | 10 | 749 |
| Decimal format, full name, en_GB [ICU] | 24,674 | 11 | 878 |
| Decimal format, grouping never, en_GB [ICU] | 41,243 | 21 | 1450 |
| Decimal format, ISO code, en_GB [ICU] | 22,825 | 10 | 878 |
| Decimal format, narrow, en_GB [ICU] | 22,532 | 10 | 816 |
| Decimal format, precision 1dp and accounting, en_GB [ICU] | 25,501 | 12 | 954 |
| Decimal format, precision 1dp, en_GB [ICU] | 22,331 | 10 | 820 |
| Decimal format, precision 2dp, en_GB [ICU] | 22,514 | 10 | 841 |
| Decimal format, separator always, en_GB [ICU] | 23,840 | 11 | 868 |
| Decimal format, sign accounting, en_GB [ICU] | 25,651 | 12 | 932 |
| Decimal format, sign always, en_GB [ICU] | 24,593 | 11 | 897 |
| Decimal format, sign never, en_GB [ICU] | 24,565 | 11 | 889 |
| Decimal from MoneyOf | 257 | 0 | 9 |
| Decimal parse, en_GB [ICU] | 24,897 | 8 | 944 |
| Money format, default, en_GB [engine] | 14,696 | 0 | 566 |
| Money from Decimal | 17,844 | 11 | 582 |
| Money parse, en_GB [ICU] | 44,895 | 19 | 1688 |
| MoneyLocalization moneyFormat, en_GB | 8,089 | 0 | 332 |
| MoneyLocalization moneyFormat, ISO code, en_GB | 8,358 | 0 | 356 |
| MoneyOf attributed, default, en_GB [engine] | 213,250 | 59 | 9538 |
| MoneyOf format, default, en_GB [engine] | 15,160 | 0 | 569 |
| MoneyOf format, every option, en_GB [engine] | 16,047 | 0 | 654 |
| MoneyOf format, full name, en_GB [engine] | 18,083 | 1 | 707 |
| MoneyOf format, grouping never, en_GB [engine] | 15,066 | 0 | 575 |
| MoneyOf format, increment, en_GB [ICU fallback] | 29,604 | 13 | 1094 |
| MoneyOf format, ISO code, en_GB [engine] | 15,244 | 0 | 590 |
| MoneyOf format, narrow, en_GB [engine] | 14,904 | 0 | 577 |
| MoneyOf format, precision 1dp and accounting, en_GB [engine] | 15,347 | 0 | 595 |
| MoneyOf format, precision 1dp, en_GB [engine] | 15,088 | 0 | 586 |
| MoneyOf format, precision 2dp, en_GB [engine] | 15,626 | 0 | 621 |
| MoneyOf format, separator always, en_GB [engine] | 14,712 | 0 | 565 |
| MoneyOf format, sign accounting, en_GB [engine] | 15,116 | 0 | 602 |
| MoneyOf format, sign always, en_GB [engine] | 14,990 | 0 | 594 |
| MoneyOf format, sign never, en_GB [engine] | 14,839 | 0 | 624 |
| MoneyOf from a negative Decimal | 18,505 | 11 | 613 |
| MoneyOf from Decimal | 17,842 | 11 | 586 |
| MoneyOf parse, en_GB [ICU] | 45,984 | 19 | 1732 |

### Harness floor

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 0 |

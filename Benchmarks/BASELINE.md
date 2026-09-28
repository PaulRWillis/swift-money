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
| Chained scaling (three rates) | 7454 | 717 | 473 |

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
| MoneyOf description | 430 | 0 | 14 |
| MoneyOf description, large negative | 1638 | 1 | 69 |
| MoneyOf equality | 7 | 0 | 1 |
| MoneyOf hashing | 152 | 0 | 7 |
| MoneyOf init exactly | 25 | 0 | 1 |
| MoneyOf is multiple | 16 | 0 | 1 |
| MoneyOf is negative | 10 | 0 | 1 |
| MoneyOf is zero | 7 | 0 | 0 |
| MoneyOf magnitude | 30 | 0 | 1 |
| MoneyOf negation | 29 | 0 | 1 |
| MoneyOf parsing | 234 | 0 | 6 |
| MoneyOf parsing a large amount | 661 | 0 | 18 |
| MoneyOf parsing a negative amount | 211 | 0 | 5 |
| MoneyOf proportion | 233 | 0 | 8 |
| MoneyOf proportion of large amounts | 365 | 0 | 15 |
| MoneyOf scalar multiplication | 14 | 0 | 1 |
| MoneyOf scalar multiplication in place | 45 | 0 | 1 |
| MoneyOf scalar multiplication near the maximum | 32 | 0 | 1 |
| MoneyOf scalar multiplication, Int32 operand | 61 | 0 | 2 |
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
| Money description | 420 | 0 | 14 |
| Money equality | 20 | 0 | 1 |
| Money hashing | 215 | 0 | 11 |
| Money init exactly | 28 | 0 | 1 |
| Money is less than, throwing | 20 | 0 | 1 |
| Money is multiple, throwing | 24 | 0 | 1 |
| Money parsing | 352 | 0 | 9 |
| Money parsing, caller's currency | 308 | 0 | 9 |
| Money proportion, throwing | 252 | 0 | 7 |
| Money scalar multiplication, amount times integer | 32 | 0 | 1 |
| Money scalar multiplication, integer times amount | 46 | 0 | 1 |
| Money subtraction in place, throwing | 14 | 0 | 1 |
| Money subtraction, throwing | 39 | 0 | 1 |

### MoneyOf.Unrounded (typed currency)

Most rows here cost several times their `Money.Unrounded` twin. The typed operators and `.unrounded` reach generic `Fixed` entry points that are not `@inlinable`, so they run unspecialized across the module boundary.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf chain, rounding each step | 717 | 0 | 36 |
| MoneyOf unrounded | 746 | 0 | 24 |
| MoneyOf unrounded addition | 37 | 0 | 1 |
| MoneyOf unrounded chain | 2091 | 0 | 94 |
| MoneyOf unrounded converted | 867 | 0 | 31 |
| MoneyOf unrounded divided | 1676 | 0 | 66 |
| MoneyOf unrounded divided exactly | 1584 | 0 | 52 |
| MoneyOf unrounded from major units | 2483 | 0 | 103 |
| MoneyOf unrounded from minor units | 29 | 0 | 1 |
| MoneyOf unrounded minus settled | 762 | 0 | 25 |
| MoneyOf unrounded plus settled | 762 | 0 | 25 |
| MoneyOf unrounded rounded | 231 | 0 | 9 |
| MoneyOf unrounded scaling | 1126 | 0 | 41 |
| MoneyOf unrounded subtraction | 37 | 0 | 1 |
| MoneyOf unrounded times an integer | 746 | 0 | 24 |
| MoneyOf unrounded total of 10 | 837 | 0 | 28 |

### Money.Unrounded (runtime currency)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money unrounded addition, throwing | 46 | 0 | 1 |
| Money unrounded applying a rate | 453 | 0 | 16 |
| Money unrounded divided by an integer | 955 | 0 | 34 |
| Money unrounded divided exactly | 1139 | 0 | 37 |
| Money unrounded minus settled, throwing | 95 | 0 | 3 |
| Money unrounded plus settled, throwing | 90 | 0 | 2 |
| Money unrounded rounded | 238 | 0 | 9 |
| Money unrounded scaling by a rate | 453 | 0 | 16 |
| Money unrounded scaling by an integer | 751 | 0 | 25 |
| Money unrounded subtraction, throwing | 46 | 0 | 1 |
| Money unrounded total of 10, throwing | 171 | 0 | 5 |

### Rate

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate equality | 19 | 0 | 1 |
| Rate from a decimal string | 1914 | 0 | 91 |
| Rate from a Double | 2561 | 0 | 95 |
| Rate from a fraction string | 1791 | 0 | 58 |
| Rate from a large decimal string | 2042 | 0 | 68 |
| Rate from a negative decimal string | 1990 | 0 | 95 |
| Rate from a negative fraction string | 2091 | 0 | 69 |
| Rate from a percent string | 2359 | 0 | 105 |
| Rate from a string literal | 1914 | 0 | 93 |
| Rate from basis points | 1013 | 0 | 37 |
| Rate from percent | 1056 | 0 | 43 |
| Rate to basis points, rounded | 266 | 0 | 8 |
| Rate to whole basis points | 163 | 0 | 5 |

### ExchangeRate and Margin

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| ExchangeRate applying a margin | 382 | 0 | 11 |
| ExchangeRate construction | 334 | 0 | 10 |
| ExchangeRate construction, across scales | 334 | 0 | 10 |
| ExchangeRate crossed | 370 | 0 | 11 |
| Margin construction | 44 | 0 | 2 |
| MoneyOf converted | 57 | 0 | 2 |

### UnitPrice

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| UnitPrice total for a fractional quantity | 401 | 0 | 12 |
| UnitPrice total for a whole quantity | 757 | 0 | 25 |

### Currency, CurrencyCode, UnitScale, AnyCurrency

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| AnyCurrency storage for a custom field | 107 | 0 | 4 |
| Currency construction, custom | 109 | 0 | 4 |
| Currency description | 155 | 0 | 6 |
| Currency equality | 26 | 0 | 1 |
| CurrencyCode description | 177 | 0 | 7 |
| CurrencyCode equality | 21 | 0 | 1 |
| CurrencyCode validation | 268 | 0 | 10 |
| CurrencyCode validation, eight characters | 490 | 0 | 17 |
| CurrencyCode validation, lowercase | 266 | 0 | 8 |
| ISO currency lookup | 87 | 0 | 3 |
| UnitScale construction | 68 | 0 | 3 |
| UnitScale from decimal places | 27 | 0 | 1 |

### Splitting: Split, WeightedSplit, Weights, PartCount, Weight

`Split.amounts` iterates through members that are `@usableFromInline` but not `@inlinable`, so every element is an unspecialized cross-module call: ~470 instructions a part.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money split by weights | 4020 | 4 | 133 |
| Money split into 3 | 62 | 0 | 2 |
| MoneyOf split by 10 weights | 5683 | 4 | 185 |
| MoneyOf split by weights | 4010 | 4 | 140 |
| MoneyOf split by weights that divide exactly | 3037 | 3 | 94 |
| MoneyOf split into 1000, materialized | 472K | 1 | 14000 |
| MoneyOf split into 3 | 58 | 0 | 2 |
| MoneyOf split, iterating the parts | 3005 | 0 | 84 |
| PartCount construction | 25 | 0 | 1 |
| Split counting the parts | 13 | 0 | 1 |
| Weight construction | 25 | 0 | 1 |
| WeightedSplit amounts | 944 | 1 | 29 |
| WeightedSplit count | 15 | 0 | 1 |
| WeightedSplit weights | 944 | 1 | 29 |
| Weights construction | 777 | 1 | 22 |

### Sequence.total

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money total of 10, throwing | 149 | 0 | 4 |
| MoneyOf total of 10 | 86 | 0 | 5 |
| MoneyOf total of 1000 | 6027 | 0 | 232 |

### Serialization: bytes, Codable, MoneyCodingFormat

The JSON rows are mostly Foundation's coder; the `Control` peer (a plain `Int64` in the same coder) is the floor. The byte serializer is fifteen bytes, allocation-free.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money bytes decode | 212 | 0 | 5 |
| Money bytes encode | 255 | 0 | 10 |
| Money encode, no coder | 796 | 0 | 32 |
| Money encode, no coder, two fields | 4691 | 1 | 152 |
| Money JSON decode | 14K | 6 | 464 |
| Money JSON decode, two fields | 54K | 29 | 1958 |
| Money JSON encode | 6712 | 2 | 242 |
| Money JSON encode, major units | 9595 | 3 | 366 |
| Money JSON encode, two fields | 28K | 11 | 1002 |
| Money Unrounded bytes decode | 228 | 0 | 6 |
| MoneyCodingFormat custom fields | 4421 | 2 | 157 |
| MoneyOf bytes decode | 174 | 0 | 5 |
| MoneyOf bytes encode | 266 | 0 | 10 |
| MoneyOf bytes encode, extremes | 266 | 0 | 9 |
| MoneyOf JSON decode, amount only | 19K | 12 | 686 |
| MoneyOf JSON encode, amount only | 10K | 3 | 353 |
| MoneyOf Unrounded bytes decode | 190 | 0 | 5 |
| MoneyOf Unrounded bytes encode | 511 | 0 | 17 |
| MoneyOf unroundedBytes | 1233 | 0 | 38 |

### MoneyFormat (Core engine)

The engine alone, rendering with a prebuilt descriptor. The `MoneyOf format` rows under *Outside Core* add building that descriptor from the packed CLDR tables on every call.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Engine format, accounting, en_GB [engine] | 2300 | 0 | 74 |
| Engine format, default, en_GB [engine] | 2231 | 0 | 74 |
| Engine format, grouped, en_GB [engine] | 2701 | 0 | 98 |
| Engine format, precision 1dp, en_GB [engine] | 2137 | 0 | 77 |
| FractionLength construction | 27 | 0 | 1 |

### Peer baselines

`Int`/`Int128` show what type safety costs, `Double` is the fast answer that is wrong at scale, `FixedPointDecimal` is the closest published peer, and `Decimal` is the exact answer that is slow. `Control` is a plain `Int64` through the same JSON coder.

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Control JSON decode | 8393 | 6 | 293 |
| Control JSON encode | 5947 | 2 | 209 |
| Decimal addition | 7127 | 6 | 219 |
| Decimal chained scaling | 55K | 41 | 1705 |
| Decimal comparison | 3933 | 4 | 123 |
| Decimal description | 6654 | 3 | 214 |
| Decimal divided by 3 | 50K | 37 | 1577 |
| Decimal from a decimal string | 4667 | 2 | 172 |
| Decimal JSON decode | 12K | 8 | 401 |
| Decimal JSON encode | 11K | 5 | 372 |
| Decimal multiplied by a rate | 13K | 10 | 411 |
| Decimal parsing | 4740 | 2 | 172 |
| Decimal scalar multiplication | 6241 | 5 | 189 |
| Decimal scaled and rounded | 107K | 83 | 3451 |
| Decimal subtraction | 7826 | 7 | 241 |
| Double addition | 6 | 0 | 0 |
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
| FixedPoint chained scaling | 473 | 0 | 31 |
| FixedPoint comparison | 15 | 0 | 1 |
| FixedPoint scalar multiplication | 150 | 0 | 5 |
| FixedPoint scaled and rounded | 179 | 0 | 8 |
| FixedPoint subtraction | 13 | 0 | 1 |
| Int addition | 9 | 0 | 1 |
| Int chained scaling, truncating | 23 | 0 | 1 |
| Int comparison | 15 | 0 | 1 |
| Int description | 470 | 0 | 16 |
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
| Decimal attributed, default, en_GB [ICU] | 146K | 39 | 5946 |
| Decimal format, default, en_GB [ICU] | 22K | 10 | 778 |
| Decimal format, every option, en_GB [ICU] | 21K | 10 | 727 |
| Decimal format, full name, en_GB [ICU] | 25K | 11 | 860 |
| Decimal format, grouping never, en_GB [ICU] | 41K | 21 | 1361 |
| Decimal format, ISO code, en_GB [ICU] | 23K | 10 | 823 |
| Decimal format, narrow, en_GB [ICU] | 23K | 10 | 797 |
| Decimal format, precision 1dp and accounting, en_GB [ICU] | 25K | 12 | 887 |
| Decimal format, precision 1dp, en_GB [ICU] | 22K | 10 | 788 |
| Decimal format, precision 2dp, en_GB [ICU] | 23K | 10 | 804 |
| Decimal format, separator always, en_GB [ICU] | 24K | 11 | 846 |
| Decimal format, sign accounting, en_GB [ICU] | 26K | 12 | 918 |
| Decimal format, sign always, en_GB [ICU] | 25K | 11 | 908 |
| Decimal format, sign never, en_GB [ICU] | 25K | 11 | 860 |
| Decimal from MoneyOf | 6315 | 5 | 195 |
| Decimal parse, en_GB [ICU] | 25K | 8 | 888 |
| Money format, default, en_GB [engine] | 15K | 0 | 567 |
| Money from Decimal | 18K | 11 | 569 |
| Money parse, en_GB [ICU] | 45K | 19 | 1600 |
| MoneyLocalization moneyFormat, en_GB | 8086 | 0 | 340 |
| MoneyLocalization moneyFormat, ISO code, en_GB | 8357 | 0 | 340 |
| MoneyOf attributed, default, en_GB [engine] | 214K | 59 | 9400 |
| MoneyOf format, default, en_GB [engine] | 15K | 0 | 595 |
| MoneyOf format, every option, en_GB [engine] | 16K | 0 | 610 |
| MoneyOf format, full name, en_GB [engine] | 19K | 1 | 686 |
| MoneyOf format, grouping never, en_GB [engine] | 16K | 0 | 582 |
| MoneyOf format, increment, en_GB [ICU fallback] | 36K | 18 | 1266 |
| MoneyOf format, ISO code, en_GB [engine] | 16K | 0 | 585 |
| MoneyOf format, narrow, en_GB [engine] | 15K | 0 | 580 |
| MoneyOf format, precision 1dp and accounting, en_GB [engine] | 16K | 0 | 653 |
| MoneyOf format, precision 1dp, en_GB [engine] | 15K | 0 | 595 |
| MoneyOf format, precision 2dp, en_GB [engine] | 16K | 0 | 619 |
| MoneyOf format, separator always, en_GB [engine] | 16K | 0 | 590 |
| MoneyOf format, sign accounting, en_GB [engine] | 16K | 0 | 610 |
| MoneyOf format, sign always, en_GB [engine] | 15K | 0 | 578 |
| MoneyOf format, sign never, en_GB [engine] | 15K | 0 | 577 |
| MoneyOf from a negative Decimal | 19K | 11 | 586 |
| MoneyOf from Decimal | 18K | 11 | 581 |
| MoneyOf parse, en_GB [ICU] | 46K | 19 | 1669 |

### Harness floor

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 0 |

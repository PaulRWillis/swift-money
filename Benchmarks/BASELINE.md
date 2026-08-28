# Performance baseline

The "before" reference for the performance-recovery work (spec §16). Every later change is measured
against these numbers, so a regression or a win is a diff, not an impression.

**Read the instruction column.** Wall-clock is noisy (CI gates it at 20% for that reason) and malloc is
near-zero across the arithmetic; the p50 **instruction count** is the stable signal, and it is the one no
CI runner exposes — which is exactly why it is captured here by hand.

Captured on Apple Silicon (arm64, macOS 26.6), Swift 6.2.4, release build, `scalingFactor: .mega`, p50 of
each metric. Reproduce with:

```sh
swift package --package-path Benchmarks --disable-sandbox --allow-writing-to-package-directory \
    benchmark --format markdown
```

## The gap this work targets

Addition, subtraction, scalar-multiply and comparison are `Int64` operations and already sit at `Int`
parity, far ahead of `Decimal`. The fractional operations are where the regression lives:

| Operation | MoneyOf | FixedPointDecimal (peer) | gap |
|---|--:|--:|--:|
| Scale by a rate and round | 2506 | 198 | **12.7×** |
| Chained scaling (three rates) | 7454 | 530 | **14.1×** |

`FixedPointDecimal` (ordo-one, `Int64`-backed, 8 fraction digits) is the realistic same-class yardstick.
The gap is not the arithmetic — it is inlining the redesign dropped across the module seam, plus a
redundant scale recomputation and a double-round. `Int128` (same storage width, truncating) shows the
floor beneath the renormalization: 27 and 107 instructions.

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
| Double addition | 6 | 0 | 0 |
| FixedPoint addition | 11 | 0 | 0 |
| Decimal addition | 7135 | 6 | 220 |

### Subtraction

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf subtraction | 8 | 0 | 0 |
| Int subtraction | 8 | 0 | 0 |
| Int128 subtraction | 11 | 0 | 1 |
| Double subtraction | 7 | 0 | 0 |
| FixedPoint subtraction | 11 | 0 | 0 |
| Decimal subtraction | 7829 | 7 | 228 |

### Scalar multiplication

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf scalar multiplication | 12 | 0 | 1 |
| Int scalar multiplication | 12 | 0 | 1 |
| Int128 scalar multiplication | 23 | 0 | 1 |
| Double scalar multiplication | 7 | 0 | 1 |
| FixedPoint scalar multiplication | 167 | 0 | 6 |
| Decimal scalar multiplication | 6240 | 5 | 181 |

### Scale by a rate and round

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf scaled and rounded | 2506 | 0 | 83 |
| Int scaled, truncating | 6 | 0 | 0 |
| Int128 scaled, truncating | 27 | 0 | 1 |
| Double scaled and rounded | 7 | 0 | 1 |
| FixedPoint scaled and rounded | 198 | 0 | 8 |
| Decimal scaled and rounded | 107K | 83 | 3186 |

### Chained scaling (three rates)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf unrounded chain | 4180 | 0 | 134 |
| MoneyOf chain, rounding each step | 7454 | 0 | 239 |
| Int chained scaling, truncating | 23 | 0 | 1 |
| Int128 chained scaling, truncating | 107 | 0 | 6 |
| Double chained scaling | 12 | 0 | 1 |
| FixedPoint chained scaling | 530 | 0 | 31 |
| Decimal chained scaling | 55K | 41 | 1633 |

### Unrounded (round-once) building blocks

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf unrounded scaling | 1777 | 0 | 53 |
| MoneyOf unrounded divided | 2378 | 0 | 76 |
| MoneyOf unrounded addition | 496 | 0 | 14 |

### Comparison

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf comparison | 13 | 0 | 0 |
| Int comparison | 13 | 0 | 0 |
| Int128 comparison | 15 | 0 | 1 |
| Double comparison | 13 | 0 | 0 |
| FixedPoint comparison | 13 | 0 | 0 |
| Decimal comparison | 3932 | 4 | 123 |

### Description

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf description | 445 | 0 | 12 |
| Money description | 437 | 0 | 12 |
| Int description | 470 | 0 | 15 |
| Double description | 524 | 0 | 17 |
| Decimal description | 6656 | 3 | 220 |

### Parsing

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf parsing | 211 | 0 | 6 |
| Money parsing | 274 | 0 | 7 |
| Int parsing | 79 | 0 | 2 |
| Double parsing | 298 | 0 | 8 |
| Decimal parsing | 4749 | 2 | 170 |

### Decimal bridge

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf from Decimal | 18K | 11 | 556 |
| Money from Decimal | 18K | 11 | 544 |
| Decimal from MoneyOf | 6338 | 5 | 189 |

### Proportion

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf proportion | 1132 | 0 | 43 |
| MoneyOf proportion of large amounts | 1147 | 0 | 45 |

### Splitting

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Weights construction | 778 | 1 | 22 |
| MoneyOf split into 3 | 56 | 0 | 2 |
| Money split into 3 | 58 | 0 | 2 |
| MoneyOf split by weights | 33K | 16 | 946 |
| Money split by weights | 4501 | 4 | 144 |
| MoneyOf split by weights that divide exactly | 33K | 16 | 1002 |
| Int quotient and remainder | 28 | 0 | 1 |
| Double divided by 3 | 9 | 0 | 0 |
| Decimal divided by 3 | 50K | 37 | 1497 |
| MoneyOf split, iterating the parts | 6326 | 0 | 190 |

### Total

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf total of 10 | 87 | 0 | 3 |

### Currency

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| CurrencyCode validation | 244 | 0 | 8 |
| ISO currency lookup | 87 | 0 | 4 |
| Money addition, throwing | 25 | 0 | 1 |
| Money addition, separately built currencies | 26 | 0 | 1 |

### Rate construction & conversion

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Rate from basis points | 970 | 0 | 32 |
| Rate from percent | 1006 | 0 | 31 |
| Rate from a decimal string | 1874 | 0 | 58 |
| Rate from a percent string | 2261 | 0 | 77 |
| Rate from a fraction string | 5587 | 3 | 187 |
| Double from a decimal string | 322 | 0 | 10 |
| Decimal from a decimal string | 4678 | 2 | 167 |
| Rate to whole basis points | 162 | 0 | 6 |
| Rate to basis points, rounded | 301 | 0 | 9 |
| Rate from a Double | 2575 | 0 | 82 |

### FX

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf converted | 1964 | 0 | 59 |
| ExchangeRate crossed | 368 | 0 | 10 |
| Double multiplied by a rate | 9 | 0 | 1 |
| Decimal multiplied by a rate | 13K | 10 | 397 |

### UnitPrice

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| UnitPrice total for a whole quantity | 1224 | 0 | 37 |
| UnitPrice total for a fractional quantity | 858 | 0 | 25 |

### Codable / JSON

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Money JSON encode | 7214 | 2 | 244 |
| Money JSON decode | 14K | 6 | 441 |
| Money JSON encode, two fields | 28K | 11 | 966 |
| Money JSON decode, two fields | 53K | 29 | 1759 |
| Control JSON encode | 5948 | 2 | 213 |
| Control JSON decode | 8418 | 6 | 278 |
| Decimal JSON encode | 11K | 5 | 366 |
| Decimal JSON decode | 12K | 8 | 395 |
| Money encode, no coder | 1285 | 0 | 42 |
| Money encode, no coder, two fields | 4312 | 1 | 129 |

### ICU formatting (Foundation)

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| MoneyOf currency formatting, en_GB | 32K | 15 | 1042 |
| Money currency formatting, en_GB | 32K | 15 | 1046 |
| Decimal currency formatting, en_GB | 22K | 10 | 759 |
| MoneyOf currency parsing, en_GB | 46K | 19 | 1575 |
| Decimal currency parsing, en_GB | 25K | 8 | 845 |

### Other

| Operation | Instructions | Malloc | Wall (ns) |
|---|--:|--:|--:|
| Harness floor, a struct | 22 | 0 | 1 |
| Harness floor, an integer | 7 | 0 | 0 |

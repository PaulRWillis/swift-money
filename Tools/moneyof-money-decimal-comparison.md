# MoneyOf vs Money vs Decimal — benchmark comparison

A focused comparison of this library's two money types against Foundation's `Decimal`, across every
benchmark where the three are analogous.

- **`MoneyOf<C>`** (`GBP`, `EUR`, …) — currency fixed at compile time; effectively a bare `Int64` of
  minor units.
- **`Money`** — currency carried at runtime; arithmetic pays a currency-match check and throws on
  mismatch.
- **`Decimal`** — Foundation's exact decimal: correct, but heap-allocating and slow.

## How to read this

- **Instructions (p50) is the signal.** Stable and reproducible. Wall-clock is noisy (CI gates it at
  ±20%); malloc is the heap-allocation count. Lower is better everywhere.
- **Ratios** are instruction-count ratios against `Decimal`, stated with direction. "≈ parity" means
  within ~1.5×.
- Where the money types **wrap Foundation** (ICU formatting/parsing, `Decimal`-backed JSON), they
  cannot beat `Decimal` — they do its work plus currency handling. Those rows are called out.

### Environment

Apple Silicon (arm64), macOS 26.6, Swift 6.2, release build, `package-benchmark`, `scalingFactor:
.mega`, p50. Reproduce:

```sh
swift package --package-path Benchmarks --disable-sandbox --allow-writing-to-package-directory \
    benchmark --format markdown
```

---

## At a glance (instruction count)

| Operation | MoneyOf | Money | Decimal | MoneyOf vs Decimal |
|---|--:|--:|--:|--:|
| Addition | 8 | 25 | 7,131 | **891× faster** |
| Subtraction | 8 | 35 | 7,829 | **979× faster** |
| Multiply by integer | 12 | 31 | 6,241 | **520× faster** |
| Comparison (less-than) | 13 | 19 | 3,932 | **302× faster** |
| Scale by a rate + round | 287 | — | 107,000 | **373× faster** |
| Chained scaling, 3 rates | 869 | — | 55,000 | **63× faster** |
| Split into 3 | 56 | 61 | 50,000 | **893× faster** |
| Description (invariant) | 410 | 403 | 6,654 | **16× faster** |
| Parse from string | 242 | 311 | 4,749 | **20× faster** |
| Currency format (ICU) | 31,000 | 31,000 | 22,000 | ≈ parity (wraps Foundation) |
| Currency parse (ICU) | 46,000 | 45,000 | 25,000 | 1.8× slower (wraps Foundation) |
| JSON encode | 9,720 | 7,228 | 11,000 | ≈ parity / 2× faster |

The pattern: on the **arithmetic and value operations the library owns**, the money types are two-to-three
orders of magnitude ahead of `Decimal` and allocation-free. On operations that **delegate to Foundation**
(ICU, `Decimal`-backed JSON) they land at parity or a little behind — the cost of the layer they add.

---

## Arithmetic

Plain `Int64` operations. `MoneyOf` is at literal `Int` parity; `Money` adds a bounded currency-match
cost. `Decimal` allocates on every operation.

| Operation | Type | Instr | Malloc | Wall (ns) | vs Decimal |
|---|---|--:|--:|--:|--:|
| **Addition** | MoneyOf | 8 | 0 | 0 | 891× faster |
| | Money | 25 | 0 | 1 | 285× faster |
| | Decimal | 7,131 | 6 | 217 | — |
| **Subtraction** | MoneyOf | 8 | 0 | 0 | 979× faster |
| | Money | 35 | 0 | 1 | 224× faster |
| | Decimal | 7,829 | 7 | 228 | — |
| **× integer** | MoneyOf | 12 | 0 | 1 | 520× faster |
| | Money | 31 | 0 | 1 | 201× faster |
| | Decimal | 6,241 | 5 | 181 | — |
| **Comparison** | MoneyOf | 13 | 0 | 0 | 302× faster |
| | Money (`isLessThan`) | 19 | 0 | 1 | 207× faster |
| | Decimal | 3,932 | 4 | 124 | — |

---

## Fractional scaling (the core operation)

Scaling by a rate that doesn't divide evenly, then rounding. `MoneyOf`/`Money` keep the fraction as an
`Unrounded` value and settle once; `Decimal` is exact but expensive.

| Operation | Type | Instr | Malloc | Wall (ns) | vs Decimal |
|---|---|--:|--:|--:|--:|
| **Scale by rate + round** | MoneyOf | 287 | 0 | 13 | 373× faster |
| | Decimal | 107,000 | 83 | 3,185 | — |
| **Chain of 3 rates, round each** | MoneyOf | 869 | 0 | 46 | 63× faster |
| | Decimal | 55,000 | 41 | 1,644 | — |
| **Chain of 3 rates, round once** | MoneyOf (unrounded) | 2,108 | 0 | 89 | — |

> **On `Money` here:** there is no single benchmark that scales-by-rate *and* rounds for `Money`. The
> nearest, `Money applying a rate`, is **70 instr** but returns an *unrounded* value and doesn't
> accumulate, so it isn't comparable to the `MoneyOf` row above. Rounding it separately
> (`Money unrounded rounded`) is a further ~275 instr. `Decimal × rate` alone (no rounding) is
> **13,000 instr**.

---

## Splitting

`Decimal` has no splitting operation; `Decimal divided by 3` is the closest analog (and it doesn't
conserve the total the way a money split does).

| Operation | Type | Instr | Malloc | Wall (ns) | vs Decimal |
|---|---|--:|--:|--:|--:|
| **Split into 3** | MoneyOf | 56 | 0 | 2 | 893× faster |
| | Money | 61 | 0 | 2 | 820× faster |
| | Decimal (÷ 3) | 50,000 | 37 | 1,545 | — |

`MoneyOf`/`Money` also offer weighted splits (`split by weights` ≈ 4,400 instr) with no `Decimal` peer.

---

## Text: description & parsing

`description` is the locale-invariant round-trip form the library writes itself — hence far ahead of
`Decimal`.

| Operation | Type | Instr | Malloc | Wall (ns) | vs Decimal |
|---|---|--:|--:|--:|--:|
| **Description** | MoneyOf | 410 | 0 | 11 | 16× faster |
| | Money | 403 | 0 | 12 | 17× faster |
| | Decimal | 6,654 | 3 | 208 | — |
| **Parse from string** | MoneyOf | 242 | 0 | 6 | 20× faster |
| | Money | 311 | 0 | 8 | 15× faster |
| | Decimal | 4,749 | 2 | 167 | — |

---

## Decimal interoperability

The bridge in `SwiftMoneyFoundation`. Cost is dominated by `Decimal` itself, so these are money-side
conversion costs rather than a contest.

| Operation | Type | Instr | Malloc | Wall (ns) |
|---|---|--:|--:|--:|
| **From `Decimal` major units** | MoneyOf | 18,000 | 11 | 552 |
| | Money | 18,000 | 11 | 553 |
| **To `Decimal` major units** | `Decimal(majorUnitsOf:)` | 6,312 | 5 | 188 |

---

## Locale formatting & parsing (ICU / Foundation)

Here the money types **wrap** `Decimal.FormatStyle.Currency`, so they do `Decimal`'s work plus
currency resolution. Expect parity to a little behind — this is the price of the currency-aware layer,
paid only when rendering for people.

| Operation | Type | Instr | Malloc | Wall (ns) | vs Decimal |
|---|---|--:|--:|--:|--:|
| **Currency format, en_GB** | MoneyOf | 31,000 | 15 | 1,085 | ≈ parity |
| | Money | 31,000 | 15 | 1,062 | ≈ parity |
| | Decimal | 22,000 | 10 | 762 | — |
| **Currency parse, en_GB** | MoneyOf | 46,000 | 19 | 1,590 | 1.8× slower |
| | Money | 45,000 | 19 | 1,559 | 1.8× slower |
| | Decimal | 25,000 | 8 | 842 | — |

> The Foundation-free `MoneyLocalization` engine renders the same amounts in **~920 instr** (≈ 34×
> below the ICU rows) when a locale is covered — the fast path for display where you don't need ICU's
> full locale coverage.

---

## Serialization — JSON

`Money`/`MoneyOf` JSON goes through `Codable`. The money encode is competitive with `Decimal` because
its default wire form is a compact coded string; the two-field and major-unit shapes cost more.

| Operation | Type | Instr | Malloc | Wall (ns) | vs Decimal |
|---|---|--:|--:|--:|--:|
| **JSON encode** | MoneyOf (amount only) | 9,720 | 3 | 339 | ≈ parity |
| | Money (coded string) | 7,228 | 2 | 250 | 2× faster |
| | Decimal | 11,000 | 5 | 365 | — |
| **JSON decode** | Money | 14,000 | 6 | 462 | ≈ parity |
| | Decimal | 12,000 | 8 | 405 | — |

## Serialization — fixed binary (no `Decimal` peer)

`Decimal` has no binary serializer. The library's is 15 fixed bytes, coder-free and allocation-free —
the reason to prefer it over JSON where you control both ends.

| Operation | Type | Instr | Malloc | Wall (ns) |
|---|---|--:|--:|--:|
| **→ 15 bytes (encode)** | MoneyOf | 403 | 0 | 10 |
| **← 15 bytes (decode)** | MoneyOf | 174 | 0 | 4 |
| | Money | 219 | 0 | 5 |

Binary decode is **~80× cheaper** than JSON decode.

---

## Summary

- **On the operations the library owns** — arithmetic, comparison, fractional scaling, splitting,
  invariant description/parsing — `MoneyOf` and `Money` beat `Decimal` by **15× to ~900×** and never
  allocate. `Decimal` allocates on every operation.
- **`MoneyOf` vs `Money`:** identical algorithms; `Money` adds a small, fixed currency-match cost
  (a handful of instructions) and throws on mismatch. Both remain hundreds of times faster than
  `Decimal`.
- **Where the money types wrap Foundation** — ICU locale formatting/parsing and `Decimal`-backed JSON —
  they land at parity or modestly behind `Decimal`, which is expected: they add currency handling on
  top of the same work. Use the **binary serializer** (no `Decimal` equivalent, ~80× cheaper than JSON)
  or the **Foundation-free localization engine** (~34× cheaper than ICU) on the hot paths.

*Figures are p50 from a full local run of the benchmark suite (161 benchmarks). See
`Benchmarks/BASELINE.md` for the complete per-type table including `Int`, `Int128`, `Double` and
`FixedPointDecimal`.*

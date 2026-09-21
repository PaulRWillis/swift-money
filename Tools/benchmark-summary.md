# swift-money — performance comparison

A benchmark comparison of this library's two money types against the primitive and third-party
alternatives, for the operations that matter most. Written to be read standalone by another agent.

## What the types are

- **`MoneyOf<Currency>`** — money whose currency is a *compile-time* type parameter (e.g. `GBP`).
  The currency carries no runtime storage, so the value is effectively a bare `Int64` of minor units.
- **`Money`** — money whose currency is a *runtime* value. Carries the currency alongside the amount,
  so arithmetic pays a small currency-match check that `MoneyOf` gets for free at compile time.

Both store whole minor units in `Int64` and round explicitly; they never use binary floating point.

## Baselines compared against

- **`Int`** — the floor: what type safety must not cost more than. Cannot round (truncates).
- **`Int128`** — the scaling engine's own working width; truncating.
- **`Double`** — the fast answer that is wrong at scale (rounds a value it cannot represent exactly).
- **`FixedPointDecimal`** — closest published peer: [ordo-one/FixedPoint](https://github.com/ordo-one/FixedPoint),
  `Int64`-backed, 8 fraction digits, same fixed-point multiply-and-round.
- **`Decimal`** — Foundation's exact decimal: correct, but slow and heap-allocating.

## How to read the numbers

- **Instructions is the signal.** p50 instruction count is stable and reproducible; wall-clock is
  noisy (CI gates it at ±20%) and malloc is near-zero across the arithmetic. Lower is better.
- **Malloc** is the heap-allocation count. `0` means the operation never touches the heap.
- **Wall (ns)** is p50 wall-clock, included for intuition only.

### Environment

Apple Silicon (arm64), macOS 26.6, Swift 6.2, release build, `package-benchmark` (ordo-one),
`scalingFactor: .mega`, p50 of each metric. Operands are drawn from an array and results are chained
so the optimizer cannot hoist the work away. Reproduce with:

```sh
swift package --package-path Benchmarks --disable-sandbox --allow-writing-to-package-directory \
    benchmark --format markdown
```

---

## Addition

| Type | Instr | Malloc | Wall (ns) |
|---|--:|--:|--:|
| **MoneyOf** | 8 | 0 | 0 |
| **Money** (runtime currency) | 25 | 0 | 1 |
| Int | 8 | 0 | 0 |
| Int128 | 11 | 0 | 1 |
| Double | 6 | 0 | 1 |
| FixedPoint | 11 | 0 | 0 |
| Decimal | 7131 | 6 | 217 |

## Subtraction

| Type | Instr | Malloc | Wall (ns) |
|---|--:|--:|--:|
| **MoneyOf** | 8 | 0 | 0 |
| **Money** (runtime currency) | 35 | 0 | 1 |
| Int | 8 | 0 | 0 |
| Int128 | 11 | 0 | 1 |
| Double | 7 | 0 | 0 |
| FixedPoint | 11 | 0 | 0 |
| Decimal | 7829 | 7 | 228 |

## Integral multiplication (amount × integer)

| Type | Instr | Malloc | Wall (ns) |
|---|--:|--:|--:|
| **MoneyOf** | 12 | 0 | 1 |
| **Money** (runtime currency) | 31 | 0 | 1 |
| Int | 12 | 0 | 1 |
| Int128 | 23 | 0 | 1 |
| Double | 7 | 0 | 1 |
| FixedPoint | 167 | 0 | 6 |
| Decimal | 6241 | 5 | 181 |

## Fractional multiplication (scale by a 7/40 rate, then round to nearest-or-even)

The operation the library exists for, and where the baselines diverge most. Only `MoneyOf`,
`FixedPoint` and `Decimal` actually round correctly; `Int`/`Int128` truncate and `Double` rounds a
binary-inexact value.

| Type | Instr | Malloc | Wall (ns) |
|---|--:|--:|--:|
| **MoneyOf** scaled + rounded | 287 | 0 | 13 |
| FixedPoint scaled + rounded | 198 | 0 | 8 |
| Int (truncates — cannot round) | 6 | 0 | 0 |
| Int128 (truncates — cannot round) | 27 | 0 | 1 |
| Double (rounds an inexact value) | 7 | 0 | 1 |
| Decimal (exact, but pays for it) | 107K | 83 | 3185 |

`MoneyOf` is **1.45× the FixedPoint peer** and **~370× faster than `Decimal`** — the intended trade:
exact decimal correctness at a small multiple of a truncating integer, not at Foundation's cost.

> **Runtime-currency `Money` is omitted from this row deliberately.** There is no single benchmark
> that scales-by-rate *and* rounds for `Money` in one shot. The nearest, `Money applying a rate`,
> is 70 instr / 2 ns, but it returns an *unrounded* value and does not accumulate, so it is not a
> like-for-like peer to the row above. Rounding the runtime result separately is another ~275 instr.

## Serialisation

The library ships a fixed-width binary serializer (15 bytes for a settled amount), coder-free and
`String`-free, so it is allocation-free and orders of magnitude below JSON. JSON goes through
`Codable` / `JSONEncoder`. `Int`/`Double`/`FixedPoint` have no analogous serialization benchmark in
the suite; `Decimal` JSON is the comparable peer.

| Operation | Instr | Malloc | Wall (ns) |
|---|--:|--:|--:|
| **MoneyOf** → 15 bytes (encode) | 403 | 0 | 10 |
| **MoneyOf** ← 15 bytes (decode) | 174 | 0 | 4 |
| **Money** ← 15 bytes (decode) | 219 | 0 | 5 |
| **Money** JSON encode | 7228 | 2 | 250 |
| **Money** JSON decode | 14K | 6 | 462 |
| **MoneyOf** JSON encode (amount only) | 9720 | 3 | 339 |
| Decimal JSON encode | 11K | 5 | 365 |
| Decimal JSON decode | 12K | 8 | 405 |

Binary decode is **~80× cheaper** than JSON decode and allocates nothing.

---

## Takeaways

- **Addition, subtraction, integral multiply** are plain `Int64` operations at literal `Int` parity
  for `MoneyOf` (8 / 8 / 12 instr) — type safety is *free*.
- **`Money`'s runtime currency** adds a small, bounded cost (25–35 instr) for the currency-match
  check — still ~200–900× cheaper than `Decimal`.
- **`Decimal` allocates on every operation** and costs thousands of instructions even for a bare add;
  it is the cost `MoneyOf`/`Money` exist to avoid while keeping exactness.
- **Fractional (rounding) work** is where real cost lives; `MoneyOf` sits just above the `FixedPoint`
  peer and vastly below `Decimal`.
- **Prefer the binary serializer** over JSON where you control both ends — ~80× faster and heap-free.

*Figures are p50 from a full local run of the benchmark suite (161 benchmarks) and match the
committed `Benchmarks/BASELINE.md`.*

# SwiftMoney

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FPaulRWillis%2Fswift-money%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/PaulRWillis/swift-money)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FPaulRWillis%2Fswift-money%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/PaulRWillis/swift-money)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/PaulRWillis/swift-money/actions/workflows/swift-macos-build.yml/badge.svg)](https://github.com/PaulRWillis/swift-money/actions/workflows/swift-macos-build.yml)
[![codecov](https://codecov.io/gh/PaulRWillis/swift-money/branch/main/graph/badge.svg)](https://codecov.io/gh/PaulRWillis/swift-money)

Type-safe money for Swift. `SwiftMoney` stores monetary values as integer minor units (`Int64`)
with the currency locked at compile time, eliminating floating-point rounding errors entirely.
Cross-currency arithmetic is a compile error, fractional operations use exact rational numbers,
and multi-currency exchange-rate conversions apply a single rounding step at the end — no matter how
many currencies are in the bag.

```swift
import SwiftMoney

let price = Money<GBP>(minorUnits: 1250)    // £12.50
let vatRate = Rate(numerator: 1, denominator: 5)!  // 20%
let vat = price.multiplied(by: vatRate, rounding: .toNearestOrAwayFromZero)

vat.result      // Money<GBP>(minorUnits: 250) — £2.50
vat.actualRate  // Rate(1/5) — exact, no precision lost
```

## Features

- **Integer minor-unit storage** — `Int64` backing; no `Decimal` overhead on the hot path
- **Compile-time currency safety** — `Money<GBP> + Money<USD>` is a compile error
- **NaN sentinel** — `Money<C>.nan` propagates through arithmetic; `isNaN` to check
- **Exact fractional multiplication** — `Rate` (GCD-reduced rational) with round-trip invariant
- **Single-rounding exchange** — `MoneyBag.total(in:using:rounding:)` accumulates exact fractions, then rounds once
- **No `Numeric` conformance** — `Money * Money` is intentionally impossible
- **Floating-point blocked** — `Money * Double` and `Money * Float` are `@available(*, unavailable)` compile errors
- **`Sendable` throughout** — all types are `Sendable`
- **Configurable Codable** — per-type encoding strategies (`.minorUnits`, `.majorUnits`, `.object`, `.string`, `.dictionary`)
- **`ParseableFormatStyle`** — locale-aware formatting and parsing with round-trip guarantee
- **Pure Swift core** — Foundation only required for `Decimal` conversions, formatting, parsing, and Codable

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/PaulRWillis/swift-money.git", from: "0.0.1"),
]
```

Then add the dependency to your target:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SwiftMoney", package: "swift-money"),
    ]
)
```

**Platforms:** macOS 15+, iOS 18+, watchOS 11+, tvOS 18+, visionOS 2+

## Types

| Type | Description |
|---|---|
| `Currency` | Protocol — adopt to define a custom currency |
| `CurrencyCode` | Validated non-empty currency code string |
| `MinimalQuantisation` | Positive `Int64`: minor units per major unit (100 for GBP, 1 for JPY) |
| `Money<C>` | Typed monetary amount stored as `Int64` minor units |
| `AnyMoney` | Type-erased money carrying currency info at runtime |
| `MoneyBag` | Multi-currency accumulator keyed by `CurrencyCode` |
| `Distribution<C>` | Result of splitting money into equal-or-near-equal parts |
| `CurrencyRegistry` | Maps currency codes to their minimal quantisation; ships with all ISO 4217 currencies |
| `Rate` | Exact rational number (GCD-reduced `numerator/denominator`) |
| `ExchangeRate<From, To>` | Typed conversion rate between two currencies |
| `ExchangeRateProvider` | Protocol — implement to supply rates from any source |

## Usage

### Defining a Currency

Five currencies are built in: `EUR`, `GBP`, `USD`, `JPY`, `CHF`. Define your own:

```swift
enum BTC: Currency {
    static let code: CurrencyCode = "BTC"
    static let minimalQuantisation: MinimalQuantisation = 100_000_000  // satoshis
}
```

`minimalQuantisation` is the number of minor units in one major unit — 100 for pence/cents,
1 for yen, 1000 for Kuwaiti dinar, 100 000 000 for satoshis.

### Creating Values

```swift
let a = Money<GBP>(minorUnits: 125)      // £1.25
let b: Money<GBP> = 500                  // £5.00 (integer literal = minor units)
let c = Money<GBP>.zero                  // £0.00
let d = Money<GBP>.nan                   // NaN sentinel
d.isNaN                                  // true
```

### Arithmetic

```swift
let price = Money<GBP>(minorUnits: 1000)  // £10.00
let tax   = Money<GBP>(minorUnits: 200)   // £2.00

price + tax              // £12.00
price - tax              // £8.00

let quantity: Int64 = 3
price * quantity         // £30.00 (Int64 scalar)

var total = price
total += tax             // £12.00
total -= tax             // £10.00
-price                   // -£10.00
```

`Money * Double` and `Money * Float` are compile errors — use `Rate` for
fractional operations.

### Distribution

Split money into equal-or-near-equal parts. The sum invariant always holds:
`distribution.sum == original`.

```swift
let amount = Money<GBP>(minorUnits: 1000)  // £10.00

switch amount.distributed(into: 3) {
case let .exact(share, count):
    // When divisible: share × count == amount
    break
case let .uneven(larger, largerCount, smaller, smallerCount):
    // larger: 334 (£3.34), largerCount: 1
    // smaller: 333 (£3.33), smallerCount: 2
    // 334 + 333 + 333 == 1000 ✓
    break
}
```

### Rate Multiplication

Use `Rate` for exact rational multiplication. The round-trip invariant holds:
`input × actualRate == result`.

```swift
let price = Money<GBP>(minorUnits: 1000)   // £10.00
let vatRate = Rate(numerator: 1, denominator: 5)!  // 20%

let vat = price.multiplied(by: vatRate, rounding: .toNearestOrAwayFromZero)
vat.result      // Money<GBP>(minorUnits: 200) — £2.00
vat.actualRate  // Rate(1/5) — exact rate applied
```

`Money * Decimal` returns an optional `RateCalculation?` (fails if the `Decimal`
cannot be represented as a `Rate`).

### Exchange Rates

```swift
// 100 GBP minor units → 135 USD minor units (£1.00 = $1.35)
let rate = ExchangeRate<GBP, USD>(from: 100, to: 135)!
let gbp = Money<GBP>(minorUnits: 1000)   // £10.00
let usd = rate.convert(gbp)              // $13.50
```

Implement `ExchangeRateProvider` to supply rates from any source:

```swift
struct MyRates: ExchangeRateProvider {
    func rate<From, To>(
        from: From.Type, to: To.Type
    ) -> ExchangeRate<From, To>? {
        // Return rates for known pairs, nil for unknown
    }
}
```

### Type Erasure

```swift
let gbp = Money<GBP>(minorUnits: 500)
let erased: AnyMoney = gbp.erased              // type-erased
let recovered: Money<GBP>? = erased.asMoney(GBP.self)  // recover typed value
```

Use `AnyMoney` for heterogeneous collections or when the currency is determined at runtime.

### MoneyBag

```swift
var bag = MoneyBag()
bag.add(Money<GBP>(minorUnits: 500))    // £5.00
bag.add(Money<EUR>(minorUnits: 1000))   // €10.00
bag += Money<GBP>(minorUnits: 200)      // adds to existing GBP

bag.balance(of: GBP.self)   // Money<GBP>(minorUnits: 700)
bag.currencyCodes           // Set(["EUR", "GBP"])
bag.balances               // [AnyMoney] sorted by code

// Convert everything to one currency (single rounding step)
let result = bag.total(in: USD.self, using: MyRates(), rounding: .toNearestOrEven)
result?.total               // Money<USD> — the rounded sum
```

### Formatting

```swift
import Foundation

let price = Money<GBP>(minorUnits: 12550)  // £125.50
let locale = Locale(identifier: "en_GB")

price.formatted()                                    // system locale default
price.formatted(.locale(locale))                     // "£125.50"
price.formatted(.grouping(.never).locale(locale))    // "£125.50" (no thousands separator)
price.formatted(.precision(.fractionLength(0)).locale(locale))  // "£126"
```

`AnyMoney` and `MoneyBag` also support formatting:

```swift
let erased = price.erased
erased.formatted()                    // resolves currency from runtime code

let bag = MoneyBag(price)
bag.formatted(locale: locale)         // "£125.50" (entries joined by ", ")
```

### Parsing

`Money<C>.FormatStyle` conforms to `ParseableFormatStyle`:

```swift
let format = Money<GBP>.FormatStyle(locale: Locale(identifier: "en_GB"))
let parsed = try Money<GBP>("£125.50", format: format)  // Money<GBP>(minorUnits: 12550)

// Round-trip guarantee:
format.parseStrategy.parse(format.format(parsed)) == parsed  // true
```

### Codable

Each type has configurable encoding/decoding strategies:

```swift
// Money<C> — default: .object → {"currencyCode":"GBP","amount":125}
let encoder = JSONEncoder()
encoder.moneyEncodingStrategy = .minorUnits   // bare 125
encoder.moneyEncodingStrategy = .majorUnits   // bare 1.25
encoder.moneyEncodingStrategy = .string       // "£1.25"

// AnyMoney — default: .full → {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125}
encoder.anyMoneyEncodingStrategy = .object(amount: .majorUnits)
// → {"currencyCode":"GBP","amount":1.25}

// MoneyBag — default: .full → {"entries":[...]}
encoder.moneyBagEncodingStrategy = .dictionary(amount: .majorUnits)
// → {"GBP":1.25,"USD":10.00}
```

`AnyMoney` and `MoneyBag` `.object`/`.dictionary` decoding strategies require a resolver closure
to map currency codes back to `MinimalQuantisation` values. Use
`CurrencyRegistry.isoStandard.asResolver()` for all standard currencies:

```swift
let decoder = JSONDecoder()
decoder.anyMoneyDecodingStrategy = .object(
    amount: .majorUnits,
    resolver: CurrencyRegistry.isoStandard.asResolver()
)
```

## Safety

- **NaN** — `Money<C>.nan` is a named sentinel (`Int64.min`); `isNaN` to check; NaN propagates through all arithmetic; NaN ≠ NaN
- **Overflow** — `+`, `-`, `*` trap on overflow, matching Swift `Int` behaviour
- **Type safety** — `Money<GBP> + Money<USD>` is a compile error; no runtime currency checks needed
- **Floating-point blocked** — `Money * Double` and `Money * Float` are `@available(*, unavailable)` with descriptive error messages
- **No `Numeric`** — `Money` does not conform to `Numeric`, preventing `money * money`
- **Foundation optional** — formatting, parsing, `Decimal` conversions, and Codable require Foundation; core arithmetic does not (`#if canImport(Foundation)` guards)

## Building and Testing

```bash
swift build
swift test    # 730+ tests
```

## Benchmarks

SwiftMoney's `Int64` minor-unit arithmetic is significantly faster than `Foundation.Decimal`:

- **Core arithmetic** (`+`, `-`, `*`, `<`): orders of magnitude faster, zero heap allocations
- **JSON encoding**: faster with `.minorUnits` strategy (bare integer vs string round-trip)
- **Formatting**: comparable — both delegate to Foundation's ICU number formatter

See **[BENCHMARKS.md](BENCHMARKS.md)** for the full side-by-side comparison, analysis, and detailed
percentile tables.

Run benchmarks locally:

```bash
swift package --package-path Benchmarks benchmark run
```

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.

# SwiftMoney

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FPaulRWillis%2Fswift-money%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/PaulRWillis/swift-money)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FPaulRWillis%2Fswift-money%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/PaulRWillis/swift-money)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)
[![CI](https://github.com/PaulRWillis/swift-money/actions/workflows/swift-macos-build.yml/badge.svg)](https://github.com/PaulRWillis/swift-money/actions/workflows/swift-macos-build.yml)
[![coverage](https://raw.githubusercontent.com/PaulRWillis/swift-money/assets/coverage.svg)](https://github.com/PaulRWillis/swift-money/actions/workflows/swift-code-coverage.yml)

Exact money arithmetic for Swift. An amount is a whole number of its currency's smallest unit,
so there is no floating point and no hidden rounding. The currency is part of the type when you
know it at compile time, and checked at runtime when you do not.

```swift
import SwiftMoney

let price = GBP(minorUnits: 4_99)                              // GBP 4.99
let vat = price.scaled(by: "20%", rounding: .toNearestOrEven)  // GBP 1.00
let total = price + vat                                        // GBP 5.99
```

## Features

- **Exact by construction.** Amounts are `Int64` minor units. Rates are exact fractions.
  `Double` never touches arithmetic.
- **Two levels of currency safety.** `GBP + EUR` fails to compile. `Money` carries its currency
  at runtime, and mixing two currencies throws.
- **One rounding step, at the end.** Chain exact operations with `unrounded`, then settle once.
- **Splits that always add up.** Even and weighted splits return parts that sum exactly to the
  original amount.
- **165 ISO 4217 currencies built in**, every code with a stated minor unit, and a custom
  currency takes three lines.
- **Locale-aware formatting and parsing**, in a separate Foundation module.
- **Exact JSON by default**, with configurable wire formats.
- **Zero dependencies.** The core imports nothing, not even Foundation. Every value the library
  produces is `Sendable`.

## Installation

Add the package in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/PaulRWillis/swift-money.git", from: "0.6.2"),
]
```

Then add the products your target needs:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "SwiftMoney", package: "swift-money"),
        .product(name: "SwiftMoneyFoundation", package: "swift-money"),
    ]
),
```

`SwiftMoney` is the core library. `SwiftMoneyFoundation` adds the pieces that need Foundation:
formatting, localized parsing, `Decimal` interop, and JSON configuration. Import both modules to
use them.

**Requires Swift 6.2.**
**Platforms:** macOS 15+, iOS 18+, watchOS 11+, tvOS 18+, visionOS 2+. Linux builds in CI.

## Creating money

`GBP`, `EUR`, `USD` and `JPY` are ready to use. The other ISO 4217 currencies live in the
`Currencies` namespace; give the ones you use a short name:

```swift
let price = GBP(minorUnits: 4_99)   // GBP 4.99
let fare = JPY(minorUnits: 499)     // JPY 499

typealias CHF = MoneyOf<Currencies.CHF>
let fee = CHF(minorUnits: 12_50)    // CHF 12.50
```

Amounts count the currency's smallest unit: pence, cents, yen. `init(minorUnits:)` takes any
integer type and traps when the value does not fit. For values from outside the program,
`init?(exactly:)` returns `nil` instead:

```swift
GBP(exactly: unvalidatedAmount)     // nil when the amount does not fit
```

## Arithmetic

```swift
let price = GBP(minorUnits: 10_00)
let tax = GBP(minorUnits: 2_00)

price + tax        // GBP 12.00
price - tax        // GBP 8.00
price * 3          // GBP 30.00
-price             // GBP -10.00

let refund = -price
refund.isNegative  // true
refund.magnitude   // GBP 10.00
```

Amounts with a compile-time currency compare, sort, and total:

```swift
let expenses = [GBP(minorUnits: 5_20), GBP(minorUnits: -2_40), GBP(minorUnits: 3_38)]

expenses.max()     // GBP 5.20
expenses.total()   // GBP 6.18
```

Overflow traps, exactly as `Int` overflow does. There is no `money * money`, because money
squared has no meaning.

## Runtime currencies

When the currency only arrives at runtime, use `Money`. It stores the currency inside the value,
and combining two amounts throws when their currencies differ. One `try` covers a whole
expression:

```swift
let price = Money(minorUnits: 4_99, currency: .gbp)
let delivery = Money(minorUnits: 2_00, currency: .gbp)

let total = try (price * 3) + delivery   // GBP 16.97

let euros = Money(minorUnits: 5_00, currency: .eur)
try price + euros   // throws MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)
```

`Money` has no `<`, because no order exists between five pounds and five euros. Sort through the
throwing comparison instead:

```swift
let ordered = try prices.sorted { try $0.isLessThan($1) }
```

## Formatting for display

Formatting is locale-aware and lives in `SwiftMoneyFoundation`:

```swift
import SwiftMoney
import SwiftMoneyFoundation

let price = GBP(minorUnits: 4_99)

price.formatted()                                               // "£4.99" for a user in the UK
price.formatted(.currency(locale: Locale(identifier: "en_GB")))  // "£4.99"
```

The style does not need a currency code, because the amount carries its own. A style is also a
value you can configure and keep, with the vocabulary of Foundation's currency styles:
presentation, grouping, sign, precision, and display rounding.

```swift
let style = CHF.FormatStyle(locale: Locale(identifier: "en_CH")).rounded(increment: 5)

style.format(CHF(minorUnits: 4_98))   // "CHF 5.00", Swiss cash rounding
```

## Percentages and fractions

`Ratio` is an exact fraction. Write one as a percent, a fraction, or a decimal; each converts
exactly:

```swift
let vat: Ratio = "20%"          // equal to "1/5" and "0.2"
Ratio(exactly: 1, over: 3)      // from runtime values; nil when invalid
```

Scale an amount and choose the rounding, or pattern-match to learn what was lost:

```swift
price.scaled(by: "20%", rounding: .toNearestOrEven)   // GBP 1.00

switch price.scaled(by: "1/3") {
case .exact(let amount):
    // the ratio divided evenly
case .inexact(let amount, let remainder):
    // amount is truncated; remainder holds the exact leftover
}
```

Chain exact steps with `unrounded` and settle once, so rounding error cannot accumulate:

```swift
let net = GBP(minorUnits: 4_99)
let delivery = GBP(minorUnits: 2_00)

let payable = (net.unrounded * "17.5%" + delivery.unrounded)
    .rounded(.toNearestOrAwayFromZero)
```

## Splitting

Splits return parts that sum exactly to the original, with the leftover minor units spread one
per part:

```swift
let bill = GBP(minorUnits: 100_00)

Array(bill.split(into: 3).amounts)   // [GBP 33.34, GBP 33.33, GBP 33.33]
bill.split(by: [60, 30, 10])         // [GBP 60.00, GBP 30.00, GBP 10.00]
```

A weighted split keeps weight order and hands leftovers to the largest remainders, so each part
sits within one minor unit of its exact share.

## Parsing text

The core parser reads two exact forms and no locale:

```swift
GBP(string: "4.99")          // GBP 4.99: a decimal point means major units
GBP(string: "499")           // GBP 4.99: no decimal point means minor units
Money(string: "EUR 20.00")   // the ISO 4217 table supplies the scale
```

Each initializer is failable. A decimal too fine for the currency returns `nil`, never a rounded
value. `description` prints the same coded form, `"GBP 4.99"`, so values round-trip through
logs.

Localized input goes through the format style's parse strategy:

```swift
let style = GBP.FormatStyle(locale: Locale(identifier: "en_GB"))

try style.parseStrategy.parse("£4.99")   // GBP 4.99
```

## JSON

An amount encodes as one exact string by default, so no reader can misplace a decimal point:

```swift
try JSONEncoder().encode(GBP(minorUnits: 4_99))   // "GBP 499"
```

Wire shape is a property of the coder, configured in `SwiftMoneyFoundation`:

```swift
let encoder = JSONEncoder()
encoder.moneyCodingFormat = .fields

try encoder.encode(price)   // {"currency":"GBP","amount":499}
```

Decoding accepts every default shape the library writes, and the payload itself decides which
arrived. Two choices must also be set on the decoder, because the payload cannot carry them:
custom field keys, and major units written as bare numbers.

## Decimal interop

```swift
import SwiftMoneyFoundation

Decimal(majorUnitsOf: GBP(minorUnits: 4_99))   // exactly 4.99
GBP(majorUnits: decimalAmount)                 // nil rather than round when the value is too fine
```

Reading an amount as a plain integer needs no Foundation, and names its units the same way:

```swift
Int(minorUnitsOf: GBP(minorUnits: 4_99))   // Optional(499)
Int(minorUnitsOf: JPY(minorUnits: 499))    // Optional(499)
```

It is optional because the width an amount is stored in is private, and `Int` holds only 32 bits
on watchOS.

## Custom currencies

A currency is a code plus a unit scale, the count of smallest units in one major unit:

```swift
enum LoyaltyPoints: CurrencyType {
    static let currency = Currency(code: "LTY", unitScale: 1)
}

typealias Points = MoneyOf<LoyaltyPoints>
let balance = Points(minorUnits: 250)   // LTY 250
```

For a currency known only at runtime, build a `Currency` value and use `Money`. A scale is valid
when it has an exact decimal form: any `2^a * 5^b`, to at most eighteen decimal places. So 100,
10, 5, and 256 all work, and US Treasury bond pricing in 256ths is representable.

## Design

- **Overflow traps; bad data throws.** Arithmetic overflow is a programming error and traps like
  `Int`. A currency mismatch is bad data and throws `MoneyError`, the caller's to handle.
- **Literals trap; data is failable.** Every literal that can be invalid traps at the source
  line. Every runtime input has a failable or throwing twin.
- **`Double` never touches arithmetic.** Fractions go through `Ratio`, which is exact.
- **No global state.** There is no currency registry. Every type is a value, and every value the
  library produces is `Sendable`.

## Building and testing

```bash
swift build
swift test
```

## Benchmarks

Benchmarks live in a separate package and need jemalloc (`brew install jemalloc`):

```bash
swift package --package-path Benchmarks --disable-sandbox benchmark
```

See **[BENCHMARKS.md](https://github.com/PaulRWillis/swift-money/blob/assets/BENCHMARKS.md)**
for the recorded results.

## License

Apache License 2.0. See [LICENSE](LICENSE) for details, and
[ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md) for the sources that influenced this library.

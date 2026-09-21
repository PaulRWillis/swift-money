# SwiftMoney — API examples

Simple, copy-pasteable Swift for every public operation. Grouped by task. Accurate to the current
source (types: `MoneyOf<Currency>`, its runtime alias `Money`, `Rate`, `ExchangeRate`, `Currency`, and
the splitting / formatting / serialization surface).

## Import

```swift
import SwiftMoney            // umbrella: Core + Foundation formatting + localization + Decimal/JSON
// or, on Embedded / Foundation-free targets:
import SwiftMoneyCore        // the money types and arithmetic only
```

`MoneyOf<C>` is the one money type. Two currency representations specialise it:

- **`MoneyOf<SomeCurrencyType>`** — currency fixed at compile time. `GBP`, `EUR`, `USD`, `JPY` are
  ready-made aliases; every ISO code is `MoneyOf<Currencies.XYZ>`. Arithmetic never throws; mixing
  currencies is a compile error.
- **`Money`** (= `MoneyOf<AnyCurrency>`) — currency carried at runtime. Arithmetic that combines two
  amounts **throws** `MoneyError.currencyMismatch` when they disagree.

---

## Creating amounts

### Compile-time currency (`GBP`, `EUR`, `USD`, `JPY`, …)

```swift
let a = GBP(minorUnits: 4_99)          // £4.99 — the argument is always minor units (pence)
let b = JPY(minorUnits: 499)           // ¥499  — yen have no minor unit
let c = EUR(minorUnits: 0)             // €0.00
let z = GBP.zero                       // £0.00
let lo = GBP.min                       // smallest representable
let hi = GBP.max                       // largest representable

// Validating form for values from outside the program (nil instead of a trap on overflow):
let maybe = GBP(exactly: someHugeInt)  // GBP?

// Any ISO currency that has no top-level alias:
let chf = MoneyOf<Currencies.CHF>(minorUnits: 5_00)
typealias CHF = MoneyOf<Currencies.CHF>   // alias it yourself if you use it a lot
```

### Runtime currency (`Money`)

```swift
let price = Money(minorUnits: 4_99, currency: .gbp)   // .gbp, .eur, .usd, .jpy, … are provided
let yen   = Money(minorUnits: 499, currency: .jpy)
let maybe = Money(exactly: someHugeInt, currency: .gbp)   // Money?
```

### From a string

```swift
GBP(string: "4.99")        // £4.99  (a "." means major units)
GBP(string: "499")         // £4.99  (no "." means minor units)
GBP(string: "GBP 4.99")    // £4.99  (code optional; must match if present)
GBP(string: "USD 4.99")    // nil

Money(string: "GBP 4.99")  // code REQUIRED for Money (nothing else gives the scale)
Money(string: "JPY 499")   // ¥499
Money(string: "4.99")      // nil
```

### From `Decimal` major units (needs `SwiftMoneyFoundation`)

```swift
GBP(majorUnits: Decimal(string: "4.99")!)          // £4.99
JPY(majorUnits: Decimal(4.99))                     // nil — yen can't hold 4.99
Money(majorUnits: listedDecimal, currency: .gbp)   // Money?
// Nothing is rounded: a value finer than the currency divides returns nil.
```

### A custom currency (crypto, commodity, loyalty points…)

```swift
// Compile-time: conform a caseless enum to CurrencyType.
enum LoyaltyPoints: CurrencyType {
    static let currency: Currency = {
        guard let currency = Currency(code: "LTY", unitScale: 1) else {
            preconditionFailure("LTY must not be a currency the library ships")
        }
        return currency
    }()
}
typealias Points = MoneyOf<LoyaltyPoints>
let earned = Points(minorUnits: 250)               // 250 points

// Runtime: build a Currency value and pass it in.
let btc = Currency(code: "BTC", unitScale: 100_000_000)     // Currency? (8 decimal places)
let sats = btc.map { Money(minorUnits: 50_000, currency: $0) }
```

---

## Reading an amount

```swift
let money = GBP(minorUnits: 4_99)

money.currency                     // Currency (code + unitScale)
String(describing: money)          // "GBP 4.99" — locale-invariant, round-trips

Int(minorUnitsOf: money)           // 499  (Int?, nil if it doesn't fit the target width)
Int64(minorUnitsOf: money)         // 499

import SwiftMoneyFoundation
Decimal(majorUnitsOf: money)       // 4.99 — exact, never fails, never rounds
```

---

## Arithmetic — compile-time currency (non-throwing)

```swift
let x = GBP(minorUnits: 4_99)
let y = GBP(minorUnits: 1_00)

x + y                              // £5.99
x - y                              // £3.99
x * 3                              // £14.97  (money × integer)
3 * x                              // £14.97  (integer × money)
var m = x; m *= 3                  // in place
-x                                 // -£4.99
x.magnitude                        // £4.99   (sign removed)
x.isNegative                       // false

x < y                              // false — full Comparable: <, <=, >, >=, ==
x == y                             // false
[y, x].max()                       // £4.99
[y, x].sorted()                    // [£1.00, £4.99]

x.isMultiple(of: GBP(minorUnits: 1_00))   // false

// GBP + EUR                       // ❌ compile error — different types
```

## Arithmetic — runtime currency (`Money`, throwing)

```swift
let p = Money(minorUnits: 4_99, currency: .gbp)
let q = Money(minorUnits: 1_00, currency: .gbp)

try p + q                          // £5.99   — throws MoneyError.currencyMismatch if currencies differ
try p - q                          // £3.99
p * 3                              // £14.97  — scalar multiply never throws (one currency in, one out)
3 * p
var r = p; try r += q              // in place (r untouched if it throws)

try p.isLessThan(q)                // Bool — Money is NOT Comparable (no total order across currencies)
try prices.sorted { try $0.isLessThan($1) }
try prices.max { try $0.isLessThan($1) }

try p.isMultiple(of: q)            // Bool

// One `try` covers a whole expression:
let total = try (p * 3) + q - r
```

`MoneyError`:

```swift
do {
    _ = try p + Money(minorUnits: 1, currency: .eur)
} catch let error as MoneyError {
    // .currencyMismatch(lhs: Currency, rhs: Currency)
}
```

---

## Scaling by a rate (fractional multiplication) — the core operation

A rate need not divide into whole minor units, so `applying(_:)` returns an **`Unrounded`** value that
you settle with `rounded(_:)`, choosing the rule. This is where money is normally lost — settle **once**,
at the end, not at every step.

```swift
let vat: Rate = "0.175"                    // 17.5% (string literal)

GBP(minorUnits: 10).applying(vat)                        // Unrounded (1.75p, fraction kept)
GBP(minorUnits: 10).applying(vat).rounded(.toNearestOrEven)   // 2p
GBP(minorUnits: 10).applying(vat).rounded(.up)                // 2p (ceiling)

// Runtime currency works the same way:
Money(minorUnits: 10, currency: .gbp).applying(vat).rounded(.toNearestOrEven)
```

### Building a `Rate`

```swift
Rate.percent(50)                   // 0.5
Rate.basisPoints(5_000)            // 0.5  (1 bp = 0.01%)

Rate(string: "0.175")              // Rate?  — decimal
Rate(string: "17.5%")              // Rate?  — percentage
Rate(string: "1/3")                // Rate?  — fraction (rounded to the grid)
Rate(string: "1/3", rounding: .up) // choose the rounding
Rate(approximating: 0.175)         // Rate?  — closest representable to a Double

let literal: Rate = "0.175"        // ExpressibleByStringLiteral (traps if not exactly representable)
let frac: Rate = "1/4"             // fine
// let bad: Rate = "1/3"           // traps — not exact; use Rate(string:) to round

vat.wholeBasisPoints               // Int? — 1750, or nil if not a whole number of bp
vat.basisPoints(rounding: .toNearestOrEven)   // Int — 1750
```

---

## Unrounded money & chains (round once)

`.unrounded` opts an amount into fraction-keeping arithmetic; `.rounded(_:)` settles back to whole
minor units.

```swift
let balance = GBP(minorUnits: 10_000_00)   // £10,000

// A year of daily interest, settled ONCE:
let interest = (balance.unrounded * "0.045" * 31).divided(by: 365)
interest.rounded(.toNearestOrEven)         // ≈ £38.22

// Unrounded operators:
let u = balance.unrounded
u * ("0.045" as Rate)              // scale by a rate
u * 12                             // scale by an integer
u.applying("0.045")               // named form of * rate
u.divided(by: 365)                 // divide (precondition: n != 0)
u.divided(byExactly: 0)            // Unrounded? — nil when n == 0
u + balance.unrounded              // add two unrounded
u - balance.unrounded
u + balance                        // mix settled and unrounded (widens exactly)
u.rounded(.toNearestOrEven)        // settle → GBP

// Build fractional amounts directly:
GBP.Unrounded(majorUnits: "0.023")   // 2.3 pence
GBP.Unrounded(minorUnits: "2.3")     // 2.3 pence
```

The runtime-currency twins (`Money.Unrounded`) throw on the currency-combining operators, exactly like
`Money` itself.

---

## Proportion

`proportion(of:)` is the inverse of `applying(_:)`.

```swift
GBP(minorUnits: 20_00).proportion(of: GBP(minorUnits: 100_00))   // Rate? — 0.2

let spent = Money(minorUnits: 20_00, currency: .gbp)
try spent.proportion(of: budget)   // Rate? (throws on currency mismatch)
```

---

## Splitting

### Into N equal parts

```swift
let split = GBP(minorUnits: 100_00).split(into: 3)   // Split<GBP>
// parts always sum to the original; no two differ by more than one minor unit

split.count                        // PartCount (3)
Array(split.amounts)               // [£33.34, £33.33, £33.33] — larger parts first
for part in split.amounts { … }    // Sequence, allocation-free, re-traversable

switch split {
case let .even(group):             // group.count, group.amount
    _ = group
case let .uneven(larger, smaller): // larger/smaller each a Group of (count, amount)
    _ = (larger, smaller)
}
```

### By weights (proportional)

```swift
let weights: Weights = [60, 30, 10]                  // array literal; traps if empty / sums to 0
let ws = GBP(minorUnits: 100).split(by: weights)     // WeightedSplit<GBP>

ws.amounts                         // [£0.60, £0.30, £0.10]  (one per weight, in order)
ws.weights                         // [60, 30, 10]
ws.count                           // 3
for part in ws.parts {             // Part: (weight: Weight, amount: GBP)
    _ = (part.weight, part.amount)
}

// Validating construction (from data):
let w = Weights([Weight(exactly: 60)!, 30, 10])      // Weights? (nil if empty / all zero / overflows)
```

`Money.split(into:)` and `Money.split(by:)` are identical and non-throwing (one amount in, parts out).

---

## Totalling a sequence

```swift
[GBP(minorUnits: 1_00), GBP(minorUnits: 2_50)].total()          // £3.50 (typed: never fails)

let basket = [Money(minorUnits: 1_00, currency: .gbp),
              Money(minorUnits: 2_50, currency: .gbp)]
try basket.total()                 // Money? — nil if empty, throws on currency mismatch

// Unrounded totals settle once:
let monthly = balance.unrounded * "0.045"
Array(repeating: monthly, count: 12).total()          // MoneyOf<C>.Unrounded
```

---

## Currency conversion (FX)

```swift
// Rate is quoted per major unit: €1 buys £0.87.
let eurGbp = Rate(string: "0.87")
    .flatMap(ExchangeRate<Currencies.EUR, Currencies.GBP>.init)   // ExchangeRate? (positive only)

if let eurGbp {
    // converted() keeps the fraction; round once, into GBP:
    let gbp = EUR(minorUnits: 100_00).converted(using: eurGbp).rounded(.toNearestOrEven)

    // Apply a provider margin (spread), 0 ..< 1:
    let margin = Margin(.basisPoints(5))              // Margin? — five basis points
    if let margin {
        let customerRate = eurGbp.applyingMargin(margin)
        _ = EUR(minorUnits: 100_00).converted(using: customerRate).rounded(.toNearestOrEven)
    }
}

// Cross two rates through a shared currency (types enforce the pivot):
// eurUsd: EUR→USD, usdGbp: USD→GBP  ⇒  eurGbp: EUR→GBP
let eurGbpCrossed = eurUsd.crossed(with: usdGbp)      // ExchangeRate<EUR, GBP>
```

---

## Unit prices below a minor unit

```swift
// £0.023 per kWh — finer than a penny, held unsettled:
let tariff = UnitPrice<Currencies.GBP, String>(GBP.Unrounded(majorUnits: "0.023"), per: "kWh")

tariff.total(for: 1_000).rounded(.toNearestOrEven)    // £23.00  (whole quantity)
tariff.total(for: "350.5" as Rate).rounded(.toNearestOrEven)   // fractional quantity

tariff.amountPerUnit               // GBP.Unrounded
tariff.unit                        // "kWh"
```

---

## Rounding rules

`RoundingRule` is Foundation's `FloatingPointRoundingRule`, so any rule you know from `Double.rounded(_:)`
works:

```swift
.toNearestOrEven            // banker's rounding (default across the library)
.toNearestOrAwayFromZero   // "round half up" in everyday terms
.towardZero                // truncate
.awayFromZero
.down                      // toward −∞ (NB: moves away from zero on negatives)
.up                        // toward +∞
```

---

## Serialization — fixed binary (fastest, allocation-free)

15 bytes: amount, packed currency code, scale. No `Codable`, no `String`. Available on macOS 26 /
iOS 26 and newer.

```swift
GBP.byteCount                      // 15

let bytes = GBP(minorUnits: 4_99).bytes         // InlineArray<15, UInt8> — write to disk/wire

GBP(bytes: bytes)                  // GBP?  — nil unless the code & scale match GBP
Money(bytes: bytes)                // Money? — rebuilds the currency from the bytes

// Unrounded values have a 23-byte form too:
let ub = GBP.Unrounded(majorUnits: "0.023").bytes
GBP.Unrounded(bytes: ub)           // GBP.Unrounded?
```

## Serialization — Codable / JSON

Amounts are `Codable`. The default wire shape is the coded string `"GBP 499"`; set a
`MoneyCodingFormat` to match another API.

```swift
import SwiftMoneyFoundation

struct Product: Codable { let price: GBP }

let encoder = JSONEncoder()
try encoder.encode(Product(price: GBP(minorUnits: 4_99)))   // {"price":"GBP 499"}

// Change the shape:
encoder.moneyCodingFormat = .codedString(.majorUnits)       // "GBP 4.99"
encoder.moneyCodingFormat = .fields                          // {"currency":"GBP","amount":499}
encoder.moneyCodingFormat = .fields(amount: .number(.majorUnits))   // …"amount":4.99
encoder.moneyCodingFormat = .fields(currencyKey: "ccy", amountKey: "value")
encoder.moneyCodingFormat = .amountOnly                      // 499 (currency must come from the type; Money throws)

// Decoding must use the SAME format for numeric shapes (a number can't say major vs minor):
let decoder = JSONDecoder()
decoder.moneyCodingFormat = .fields
```

---

## Formatting for people (Foundation / ICU)

Locale-aware. The amount always carries its own currency, so there is no code to pass.

```swift
import SwiftMoneyFoundation

GBP(minorUnits: 4_99).formatted()                    // "£4.99" in a UK locale
GBP(minorUnits: 4_99).formatted(.currency())         // same, explicit style
GBP(minorUnits: 4_99).formatted(.currency(locale: Locale(identifier: "de_DE")))

// Build and tweak a style:
let style = MoneyOf<Currencies.USD>.FormatStyle(locale: Locale(identifier: "en_US"))
    .presentation(.isoCode)          // "USD 4.99"
    .grouping(.never)
    .precision(.fractionLength(2))
    .rounded(rule: .toNearestOrEven, increment: 5)   // Swiss-style cash rounding to 5 minor units
USD(minorUnits: 4_99).formatted(style)

// Parse localized text back to an amount:
let strategy = MoneyOf<Currencies.USD>.FormatStyle().parseStrategy
let amount = try strategy.parse("$4.99")             // USD

// Runtime currency needs the currency named when parsing:
let moneyStrategy = Money.FormatStyle().parseStrategy(for: .gbp)
let m = try moneyStrategy.parse("£4.99")             // Money
```

## Formatting without Foundation (Embedded, CLDR-backed)

```swift
import SwiftMoneyLocalization

if let format = MoneyLocalization.moneyFormat(for: .gbp, locale: "en-GB") {   // MoneyFormat?
    format.format(GBP(minorUnits: 4_99))                          // "£4.99"
    format.format(GBP(minorUnits: 1_234_56),
                  options: MoneyFormatOptions(grouping: true))     // "£1,234.56"
}
// presentation: .standard (symbol), .isoCode, .narrow
MoneyLocalization.moneyFormat(for: .usd, locale: "en-GB", presentation: .isoCode)
```

---

## Supporting value types (quick reference)

```swift
Currency(iso: "GBP")                       // Currency? from an ISO code
Currency(code: "BTC", unitScale: 100_000_000)   // Currency? (nil if it clashes with a shipped scale)
Currency.gbp, .eur, .usd, .jpy, …          // vetted ISO values

let code: CurrencyCode = "GBP"             // literal (traps if invalid: 3–8 chars A–Z/0–9)
CurrencyCode(string: userInput)            // CurrencyCode? for external input
String(code)                               // "GBP"

let scale: UnitScale = 100                 // literal — must be a power of ten (traps otherwise)
UnitScale(decimalPlaces: 2)                // UnitScale? (100)
UnitScale(exactly: 100)                    // UnitScale?
Int64(scale)                               // 100

let parts: PartCount = 3                   // literal, ≥ 1 (traps otherwise)
let weight: Weight = 60                    // literal, ≥ 0 (traps otherwise)
```

*Every failable initializer (`init?`) is for values from outside the program; the literal forms trap,
because a bad literal is a bug in the source. Overflowing arithmetic traps; use the `exactly:`
constructors where an out-of-range value is data, not a mistake.*

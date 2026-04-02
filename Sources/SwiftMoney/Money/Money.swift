import Foundation

public struct Money<Currency: SwiftMoney.Currency> {
    @usableFromInline
    internal let _minorUnits: Int

    /// The currency type
    public var currency: any SwiftMoney.Currency.Type {
        Currency.self
    }

    public init(minorUnits: Int) {
        self._minorUnits = minorUnits
    }
}

extension Money: CustomStringConvertible {
    public var description: String {
        self.formatted()
    }
}

#warning("Add tests to ensure these are conformed to as expected")
extension Money: Equatable {}

extension Money: Hashable {}

extension Money: Sendable {}

extension Money: Codable {}




/*

    - `.zero`
    - `.magnitude`

    - formatting (CurrencyFormatStyle from IntegerFormatStyle)

    - addition
        > associative: a + (b + c) == (a + b) + c
        > commutative: a + b == b + a

    - multiplication
        > integeral
        > fractional
        > distributive: a x (b + c) == (a x b) + (a x c)

    - distribution
        > integral (chunks)
        > `Distribution` type (`Distribution<Money>`?)

    - formatting
        > parsing using formatting options
        > attributed
        > decimalSeparator
        > grouping
        > notation
        > precision
        > presentation
        > rounded
        > scale
        > sign
        > currencyCode
        >`precision` and `notation`, etc., with comprehensive documentation for all formatting options
            (see bookmarks for Swift Forums discussion on compact notation)
        > Attributed as a FormatStyle
        > Add `Money.Currency` as in `IntegerFormatStyle.Currency`?


    - non-decimal currencies

    - serialisation
        > custom encoding + decoding

    - conformance to `DebugCustomStringConvertible`

    - additional type-safe values
        > `PositiveMoney` typealias `Credit`?
        > `NegativeMoney` typealias `Debit`?
        > `ZeroMoney`
        > `NonPositiveMoney`
        > `NonNegativeMoney`

    - handling non-decimalised currencies (which ones exist?)

    - handling "transaction minor units" vs. "tender minor units" as in Swiss Francs (CHF) of 0.01 vs. 0.05

    - init from Decimal?
        > Potentially by multiplying by minor units?
        > How handle small values like £0.003 (3/10ths pence)?

    - init from String (optional)
    - init from minor units (non optional)?

    - poison addition, subtraction, and multiplication operators for Double and Float.
    - additionally poison division operators for all number types: Int, Decimal, Double, Float (Int128? UInts? Binary ...?)

    - comparators (<, >, etc.)

    - negating prefix (-)

    - conformance to `AdditiveArithmetic`?

    * Minimal quantisation
    - When choosing 0.0001 USD as the minimal quantisation of USD, this allows us to represent a quadrillion dollars. This is more than the current M1 money supply of USD.

    - String intepolation? (Test separately to `.description`!)

    - `intValue` and `decimalValue`
 */

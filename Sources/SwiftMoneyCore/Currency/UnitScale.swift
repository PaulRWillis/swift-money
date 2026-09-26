/// How many of a currency's smallest units make one major unit, as a power of ten.
///
/// `100` for pounds and euros (two decimal places), `1` for yen (none), `100_000_000` for bitcoin
/// (eight). Stored as the number of decimal places — the exponent, not the scale — which is how ISO
/// 4217 records it ("minor unit: 2") and all a `Fixed` amount needs.
///
/// The scale is always a power of ten. Every ISO 4217 currency is decimalised, as is every
/// cryptocurrency in practice, so one smallest unit is a whole number of decimal places of a major
/// one. A scale that is not a power of ten — pre-decimal sterling at 240 pence to the pound, where one
/// penny is 0.0041666… — has no place here; a custom currency must be decimalised to be expressed.
public struct UnitScale: Equatable, Hashable, Sendable {
    // The number of decimal places, `0...18`. Eighteen is the ceiling the `Fixed` engine works to, and
    // the largest power of ten an `Int64` scale can reach.
    fileprivate let places: UInt8

    /// The most decimal places a scale can have, matching the `Fixed` engine's precision.
    private static let maxDecimalPlaces = 18

    /// How many decimal places write one of the currency's smallest units exactly.
    ///
    /// `2` for pounds, `0` for yen, `8` for bitcoin.
    @usableFromInline
    package var decimalPlaces: Int {
        Int(places)
    }

    /// Creates a unit scale from a number of smallest units per major unit, which may not be valid.
    ///
    /// - Parameter value: The number of the currency's smallest units per major unit.
    /// - Returns: `nil` unless `value` is a power of ten from `1` to `10 ^ 18` — that is, a decimalised
    ///   scale the engine can hold.
    public init?(exactly value: Int64) {
        guard let places = Self.decimalPlaces(ofPowerOfTen: value) else {
            return nil
        }

        self.places = places
    }

    /// Creates a unit scale from a number of decimal places.
    ///
    /// ```swift
    /// UnitScale(decimalPlaces: 2)   // pounds, a scale of 100
    /// UnitScale(decimalPlaces: 8)   // bitcoin, a scale of 100_000_000
    /// ```
    ///
    /// - Parameter places: The number of decimal places a smallest unit divides a major unit into.
    /// - Returns: `nil` unless `places` is `0` to `18`.
    public init?(decimalPlaces places: Int) {
        guard (0 ... Self.maxDecimalPlaces).contains(places) else {
            return nil
        }

        self.places = UInt8(places)
    }

    // The number of decimal places `value` is a power of ten of, or `nil` when it is not such a power,
    // or is out of range. `10 ^ places == value` with no multiplication that could overflow: the loop
    // divides down instead.
    private static func decimalPlaces(ofPowerOfTen value: Int64) -> UInt8? {
        guard value >= 1 else {
            return nil
        }

        var remaining = value
        var places = 0

        while remaining > 1 {
            guard remaining.isMultiple(of: 10) else {
                return nil   // keeps a factor other than ten, so not a power of ten
            }
            remaining /= 10
            places += 1
        }

        return places <= maxDecimalPlaces ? UInt8(places) : nil
    }
}

extension UnitScale: ExpressibleByIntegerLiteral {
    /// Creates a unit scale from an integer literal number of smallest units per major unit.
    ///
    /// A literal is written by a programmer rather than derived from data, so an invalid value is a
    /// mistake in the source rather than bad input: it traps instead of failing gracefully. Use
    /// ``init(exactly:)`` for any value that is not a literal.
    ///
    /// ```swift
    /// let pence: UnitScale = 100        // fine, two decimal places
    /// let none: UnitScale = 0           // traps
    /// let shillings: UnitScale = 240    // traps: 240 is not a power of ten
    /// ```
    ///
    /// - Parameter value: The number of the currency's smallest units per major unit.
    /// - Precondition: `value` is a power of ten from `1` to `10 ^ 18`.
    public init(integerLiteral value: Int64) {
        guard let places = Self.decimalPlaces(ofPowerOfTen: value) else {
            preconditionFailure("A unit scale must be a power of ten from 1 to 10 ^ 18. Value: \(value)")
        }

        self.places = places
    }
}

public extension Int64 {
    /// Creates an integer from a unit scale: the number of smallest units per major unit.
    init(_ scale: UnitScale) {
        self = UnitScale.scales[scale.decimalPlaces]
    }
}

extension UnitScale {
    // Ten to each place, 0...18, as a table: `Int64(scale)` is read on the parsing and description hot
    // paths, so it indexes this rather than recomputing a power of ten each time.
    fileprivate static let scales: [Int64] = (0 ... maxDecimalPlaces).map { places in
        Int64(UInt64.powerOfTen(places))
    }
}

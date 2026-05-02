/// A rate expressing the price of a `Currency` per unit of `U`.
///
/// `UnitRate` pairs a ``Rate`` (an exact GCD-reduced rational number) with
/// a unit identifier, representing a price such as "$72.50 per barrel".
///
/// The generic parameter `U` is not constrained to Foundation's `Dimension` —
/// any `Hashable & Sendable` type may be used as the unit. Foundation
/// extensions for `Measurement` and unit conversion are available when
/// `U` conforms to `Dimension`.
///
/// ### Example
///
/// ```swift
/// let oilPrice = UnitRate<USD, String>(Rate("14500/200")!, per: "barrel")
/// ```
///
/// - Note: Negative rates are permitted (e.g. feed-in tariff credits).
///   Zero rates are permitted (e.g. free tier).
public struct UnitRate<C: Currency, U: Hashable & Sendable>: Sendable {

    // MARK: - Stored properties

    /// The rate expressed as a major-unit price per unit of `U`.
    ///
    /// For example, `Rate("14500/200")` represents $72.50 per unit.
    public let rate: Rate

    /// The unit this rate is expressed per.
    public let unit: U

    // MARK: - Initialisers

    /// Creates a `UnitRate` from a pre-constructed ``Rate`` and a unit.
    ///
    /// This initialiser is infallible — any valid `Rate` (including negative
    /// and zero) is accepted.
    ///
    /// - Parameters:
    ///   - rate: The price per unit, expressed in major units of `C`.
    ///   - unit: The unit this price applies to.
    public init(_ rate: Rate, per unit: U) {
        self.rate = rate
        self.unit = unit
    }

    /// Creates a `UnitRate` from an explicit numerator and denominator.
    ///
    /// Returns `nil` if the numerator/denominator pair cannot form a valid
    /// ``Rate`` (i.e. denominator ≤ 0 or numerator is `Int64.min`).
    ///
    /// - Parameters:
    ///   - numerator: The numerator of the rate fraction.
    ///   - denominator: The denominator of the rate fraction (must be > 0).
    ///   - unit: The unit this price applies to.
    public init?(numerator: Int64, denominator: Int64, per unit: U) {
        guard let rate = Rate(numerator: numerator, denominator: denominator) else {
            return nil
        }
        self.rate = rate
        self.unit = unit
    }
}

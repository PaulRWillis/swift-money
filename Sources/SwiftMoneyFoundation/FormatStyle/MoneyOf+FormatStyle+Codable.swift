import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

extension MoneyOf.FormatStyle {
    // `RoundingIncrement` refuses a below-one value on decode itself. The precision goes through
    // `CodablePrecision`, Foundation's own decoder being unable to read back most of what its encoder
    // writes. `resolvedNumberingSystem` is derived from the locale, so it is never on the wire: it is
    // recomputed on decode, which keeps the encoded form identical to what the compiler synthesized
    // before it was added.
    private enum CodingKeys: String, CodingKey {
        case locale
        case presentation
        case grouping
        case sign
        case decimalSeparator
        case roundingRule
        case precision
        case roundingIncrement
    }

    /// Creates a style by decoding from the given decoder.
    ///
    /// ```swift
    /// let style = try JSONDecoder().decode(GBP.FormatStyle.self, from: json)
    /// ```
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Throws: `DecodingError.dataCorrupted` if the precision names no limit, mixes significant
    ///   digits with lengths, has a length below zero or a significant-digit count below one, puts
    ///   its fewest digits above its most, leaves out its fewest significant digits, or has a
    ///   bound Foundation's range factories would clamp, or if the rounding increment is below
    ///   one. Another `DecodingError` if a field is missing or has the wrong type.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locale = try container.decode(Locale.self, forKey: .locale)
        presentation = try container.decode(Configuration.Presentation.self, forKey: .presentation)
        grouping = try container.decode(Configuration.Grouping.self, forKey: .grouping)
        sign = try container.decode(Configuration.SignDisplayStrategy.self, forKey: .sign)
        decimalSeparator = try container.decode(
            Configuration.DecimalSeparatorDisplayStrategy.self, forKey: .decimalSeparator
        )
        roundingRule = try container.decode(Configuration.RoundingRule.self, forKey: .roundingRule)
        precision = try container.decodeIfPresent(CodablePrecision.self, forKey: .precision)?.precision
        roundingIncrement = try container.decodeIfPresent(RoundingIncrement.self, forKey: .roundingIncrement)
        resolvedNumberingSystem = NumberingSystem(locale.numberingSystem)
    }

    /// Encodes this style into the given encoder.
    ///
    /// Writes the precision as Foundation's `Precision` writes it, so an encoded precision may not
    /// decode: `.fractionLength(-1)` and `.significantDigits(0)` encode, and decoding them throws.
    ///
    /// ```swift
    /// let json = try JSONEncoder().encode(GBP.FormatStyle().precision(.fractionLength(2)))
    /// ```
    ///
    /// - Parameter encoder: The encoder to write to.
    /// - Throws: Any error `encoder` throws.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locale, forKey: .locale)
        try container.encode(presentation, forKey: .presentation)
        try container.encode(grouping, forKey: .grouping)
        try container.encode(sign, forKey: .sign)
        try container.encode(decimalSeparator, forKey: .decimalSeparator)
        try container.encode(roundingRule, forKey: .roundingRule)
        try container.encodeIfPresent(precision.map(CodablePrecision.init), forKey: .precision)
        try container.encodeIfPresent(roundingIncrement, forKey: .roundingIncrement)
    }
}

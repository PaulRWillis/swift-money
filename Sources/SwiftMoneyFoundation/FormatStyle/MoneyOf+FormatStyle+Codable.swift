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

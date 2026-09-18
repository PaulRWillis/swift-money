import SwiftMoneyCore

/// What each plural operand comes to for one monetary amount.
///
/// ```swift
/// let values = PluralOperandValues(minorUnits: 1_30, unitScale: 100)
/// values.value(of: .integerPart)          // .whole(1)
/// values.value(of: .fractionDigitCount)   // .whole(2)
/// ```
package struct PluralOperandValues: Equatable, Sendable {
    private let magnitude: UInt64
    private let scale: UInt64
    private let places: UInt64

    /// Creates the operand values for an amount of a currency.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount, in the currency's smallest units. Its sign is ignored, as plural
    ///     rules read an absolute value.
    ///   - unitScale: The currency's scale, which fixes how many fraction digits are shown.
    package init(minorUnits: Int64, unitScale: UnitScale) {
        self.magnitude = minorUnits.magnitude
        self.scale = UInt64(Int64(unitScale))
        self.places = UInt64(unitScale.decimalPlaces)
    }

    /// Returns the value `operand` takes for this amount.
    package func value(of operand: PluralOperand) -> PluralOperand.Value {
        switch operand {
        case .absoluteValue:
            fractionDigits == 0 ? .whole(integerPart) : .fractional
        case .integerPart:
            .whole(integerPart)
        case .fractionDigitCount:
            .whole(places)
        case .significantFractionDigitCount:
            .whole(significantFractionDigitCount)
        case .fractionDigits:
            .whole(fractionDigits)
        case .significantFractionDigits:
            .whole(significantFractionDigits)
        }
    }

    private var integerPart: UInt64 {
        magnitude / scale
    }

    private var fractionDigits: UInt64 {
        magnitude % scale
    }

    private var significantFractionDigits: UInt64 {
        Self.withoutTrailingZeros(fractionDigits).digits
    }

    private var significantFractionDigitCount: UInt64 {
        let stripped = Self.withoutTrailingZeros(fractionDigits)
        return stripped.digits == 0 ? 0 : places - stripped.zerosDropped
    }

    private static func withoutTrailingZeros(_ digits: UInt64) -> (digits: UInt64, zerosDropped: UInt64) {
        var digits = digits
        var zerosDropped: UInt64 = 0

        while digits > 0, digits.isMultiple(of: 10) {
            digits /= 10
            zerosDropped += 1
        }

        return (digits, zerosDropped)
    }
}

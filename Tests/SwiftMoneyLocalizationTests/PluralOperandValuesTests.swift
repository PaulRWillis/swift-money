import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

@Suite("PluralOperandValues Tests")
struct PluralOperandValuesTests {

    // The rows CLDR's own operand table gives for 1.30, 1.03, 1.00 and 1.230, expressed in the minor
    // units and scale a monetary amount is made of.
    @Test(
        "Operands follow CLDR's table",
        arguments: [
            (minorUnits: 1_30, scale: 100 as UnitScale, integerPart: 1, digitCount: 2, significantDigitCount: 1, digits: 30, significantDigits: 3),
            (minorUnits: 1_03, scale: 100, integerPart: 1, digitCount: 2, significantDigitCount: 2, digits: 3, significantDigits: 3),
            (minorUnits: 1_00, scale: 100, integerPart: 1, digitCount: 2, significantDigitCount: 0, digits: 0, significantDigits: 0),
            (minorUnits: 1_230, scale: 1_000, integerPart: 1, digitCount: 3, significantDigitCount: 2, digits: 230, significantDigits: 23),
            (minorUnits: 1, scale: 1, integerPart: 1, digitCount: 0, significantDigitCount: 0, digits: 0, significantDigits: 0),
            (minorUnits: 0, scale: 100, integerPart: 0, digitCount: 2, significantDigitCount: 0, digits: 0, significantDigits: 0),
        ]
    )
    func operandsFollowCLDRTable(
        _ row: (minorUnits: Int64, scale: UnitScale, integerPart: UInt64, digitCount: UInt64, significantDigitCount: UInt64, digits: UInt64, significantDigits: UInt64)
    ) {
        let values = PluralOperandValues(minorUnits: row.minorUnits, unitScale: row.scale)

        #expect(values.value(of: .integerPart) == .whole(row.integerPart))
        #expect(values.value(of: .fractionDigitCount) == .whole(row.digitCount))
        #expect(values.value(of: .significantFractionDigitCount) == .whole(row.significantDigitCount))
        #expect(values.value(of: .fractionDigits) == .whole(row.digits))
        #expect(values.value(of: .significantFractionDigits) == .whole(row.significantDigits))
    }

    @Test("An amount with no fraction digits shown has a whole absolute value")
    func wholeAmountHasWholeAbsoluteValue() {
        let pounds = PluralOperandValues(minorUnits: 3_00, unitScale: 100)
        let yen = PluralOperandValues(minorUnits: 3, unitScale: 1)

        #expect(pounds.value(of: .absoluteValue) == .whole(3))
        #expect(yen.value(of: .absoluteValue) == .whole(3))
    }

    @Test("An amount with a fraction has a fractional absolute value")
    func fractionalAmountHasFractionalAbsoluteValue() {
        let values = PluralOperandValues(minorUnits: 3_50, unitScale: 100)

        #expect(values.value(of: .absoluteValue) == .fractional)
    }

    @Test("A negative amount gives the same operands as its positive counterpart")
    func negativeAmountUsesItsAbsoluteValue() {
        let negative = PluralOperandValues(minorUnits: -1_30, unitScale: 100)
        let positive = PluralOperandValues(minorUnits: 1_30, unitScale: 100)

        #expect(negative.value(of: .integerPart) == positive.value(of: .integerPart))
        #expect(negative.value(of: .fractionDigits) == positive.value(of: .fractionDigits))
    }

    @Test("The most negative amount has operands rather than trapping")
    func mostNegativeAmountIsSafe() {
        let values = PluralOperandValues(minorUnits: .min, unitScale: 1)

        #expect(values.value(of: .integerPart) == .whole(Int64.min.magnitude))
    }

    // The load-bearing invariant of the whole plural path: a currency showing two fraction digits
    // always derives a fraction-digit count of two, whatever the amount. Rules that require none of
    // them, such as en's `i = 1 and v = 0`, therefore cannot fire for it.
    @Test("A currency showing two fraction digits always shows two", arguments: [0 as Int64, 1, 1_00, -1_00, 99_999_99])
    func fractionDigitCountFollowsTheCurrency(_ minorUnits: Int64) {
        let values = PluralOperandValues(minorUnits: minorUnits, unitScale: 100)

        #expect(values.value(of: .fractionDigitCount) == .whole(2))
    }
}

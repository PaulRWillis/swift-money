import SwiftMoneyCore
import Testing

@Suite("UInt64.DecimalExponent Tests")
struct UInt64DecimalExponentTests {

    @Test("An exponent from zero to nineteen is accepted", arguments: [0, 19])
    func acceptsTheRange(_ exponent: Int) {
        #expect(UInt64.DecimalExponent(exactly: exponent) != nil)
    }

    @Test("An exponent outside zero to nineteen is rejected", arguments: [-1, 20])
    func rejectsOutsideTheRange(_ exponent: Int) {
        #expect(UInt64.DecimalExponent(exactly: exponent) == nil)
    }

    @Test("A unit scale gives the exponent of its decimal places", arguments: 0 ... 18)
    func unitScaleGivesItsPlaces(_ places: Int) throws {
        let scale = try #require(UnitScale(decimalPlaces: places))

        #expect(UInt64.DecimalExponent(scale) == UInt64.DecimalExponent(exactly: places))
    }

    @Test("A fraction length gives the exponent of its digits", arguments: 0 ... 19)
    func fractionLengthGivesItsDigits(_ digits: Int) throws {
        let length = try #require(FractionLength(exactly: digits))

        #expect(UInt64.DecimalExponent(length) == UInt64.DecimalExponent(exactly: digits))
    }

    @Test(
        "A value's leading digit sits at one less than its digit count",
        arguments: [
            (0, 0),
            (9, 0),
            (10, 1),
            (99, 1),
            (100, 2),
            (UInt64.max, 19),
        ] as [(UInt64, Int)]
    )
    func leadingDigitPosition(_ value: UInt64, _ position: Int) {
        #expect(UInt64.DecimalExponent(leadingDigitOf: value) == UInt64.DecimalExponent(exactly: position))
    }

    @Test("The leading digit agrees with counting digits one by one, on each side of every power of ten", arguments: digitBoundaries)
    func leadingDigitAgreesWithCounting(_ value: UInt64) {
        var digits = 1
        var remaining = value
        while remaining >= 10 {
            remaining /= 10
            digits += 1
        }

        #expect(UInt64.DecimalExponent(leadingDigitOf: value) == UInt64.DecimalExponent(exactly: digits - 1))
    }
}

private let digitBoundaries: [UInt64] = {
    var values: [UInt64] = [0, 1, 9, 10, 11, .max]
    var power: UInt64 = 10
    for k in 1 ... 19 {
        values += [power - 1, power]
        if k < 19 {
            power *= 10
        }
    }
    return values
}()

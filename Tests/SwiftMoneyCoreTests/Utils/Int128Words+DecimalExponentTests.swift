import SwiftMoneyCore
import Testing

@Suite("Int128Words.DecimalExponent Tests")
struct Int128WordsDecimalExponentTests {

    @Test("An exponent from zero to thirty-eight is accepted", arguments: [0, 38])
    func acceptsTheRange(_ exponent: Int) {
        #expect(Int128Words.DecimalExponent(exactly: exponent) != nil)
    }

    @Test("An exponent outside zero to thirty-eight is rejected", arguments: [-1, 39])
    func rejectsOutsideTheRange(_ exponent: Int) {
        #expect(Int128Words.DecimalExponent(exactly: exponent) == nil)
    }

    @Test("Ten to the zero is one")
    func tenToTheZero() throws {
        let zero = try #require(Int128Words.DecimalExponent(exactly: 0))

        #expect(Int128Words.powerOfTen(zero) == 1)
    }

    @Test("Ten to the thirty-eight is the largest power held")
    func tenToTheThirtyEight() throws {
        let largest = try #require(Int128Words.DecimalExponent(exactly: 38))

        #expect(Int128Words.powerOfTen(largest) == 100_000_000_000_000_000_000_000_000_000_000_000_000)
    }

    @Test("Each power of ten is ten times the one before", arguments: 1 ... 38)
    func eachPowerIsTenTimesThePrevious(_ exponent: Int) throws {
        let current = try #require(Int128Words.DecimalExponent(exactly: exponent))
        let previous = try #require(Int128Words.DecimalExponent(exactly: exponent - 1))

        #expect(Int128Words.powerOfTen(current) == Int128Words.powerOfTen(previous) * 10)
    }
}

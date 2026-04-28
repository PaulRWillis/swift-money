import Foundation
import Testing
import SwiftMoney

@Suite("FractionalRate - FormatStyle")
struct FractionalRateFormatStyleTests {

    // MARK: - Fraction formatting

    @Test("Formats 3/4 as fraction")
    func formatThreeQuarters() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted(.fraction) == "3/4")
    }

    @Test("Formats -1/10 as fraction")
    func formatNegativeRate() throws {
        let rate = try #require(FractionalRate(numerator: -1, denominator: 10))
        #expect(rate.formatted(.fraction) == "-1/10")
    }

    @Test("Formats 0/1 as fraction")
    func formatZero() throws {
        let rate = try #require(FractionalRate(numerator: 0, denominator: 1))
        #expect(rate.formatted(.fraction) == "0/1")
    }

    @Test("Formats 1/1 as fraction")
    func formatUnit() throws {
        let rate = try #require(FractionalRate(numerator: 1, denominator: 1))
        #expect(rate.formatted(.fraction) == "1/1")
    }

    @Test("GCD-reduced: 2/4 formats as 1/2")
    func formatGCDReduced() throws {
        let rate = try #require(FractionalRate(numerator: 2, denominator: 4))
        #expect(rate.formatted(.fraction) == "1/2")
    }

    @Test("Formats 11/100 as fraction")
    func formatElevenHundredths() throws {
        let rate = try #require(FractionalRate(numerator: 11, denominator: 100))
        #expect(rate.formatted(.fraction) == "11/100")
    }

    @Test("Default formatted() uses fraction mode")
    func formattedDefaultIsFraction() throws {
        let rate = try #require(FractionalRate(numerator: 3, denominator: 4))
        #expect(rate.formatted() == "3/4")
    }

    @Test("FormatStyle() default mode is fraction")
    func defaultModeIsFraction() throws {
        let style = FractionalRate.FormatStyle()
        let rate = try #require(FractionalRate(numerator: 7, denominator: 8))
        #expect(style.format(rate) == "7/8")
    }
}

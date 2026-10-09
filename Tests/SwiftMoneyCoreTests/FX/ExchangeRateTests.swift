import SwiftMoneyCore
import SwiftMoneyCoreTestSupport
import Testing

// A currency at the coarsest scale (no minor units), for pairing against `HighPrecision` to force a
// rescale wide enough to overflow `Fixed`.
private enum LowPrecision: CurrencyType {
    static let currency = customCurrency(code: "LOW", unitScale: 1)
}

// A currency at the finest scale the engine allows, so a rate rescaled against `LowPrecision` is
// genuinely unrepresentable rather than merely large.
private enum HighPrecision: CurrencyType {
    static let currency = customCurrency(code: "HGH", unitScale: 1_000_000_000_000_000_000)
}

// Eighteen decimal places, as ether has, so a rate from it holds only a couple of places per coin.
private enum Ether: CurrencyType {
    static let currency = customCurrency(code: "ETH", unitScale: 1_000_000_000_000_000_000)
}

@Suite("Exchange Rate Tests")
struct ExchangeRateTests {

    // An ETH→GBP rate holds pence per wei to 18 places: two places of pounds per ether.
    @Test("A quote with more places than the rate holds builds no rate, rather than a rounded one")
    func inexactQuoteIsNil() throws {
        let twoPlaces = try #require(Rate(string: "3200.12"))
        let threePlaces = try #require(Rate(string: "3200.125"))

        #expect(FX.ExchangeRateOf<Ether, Currencies.GBP>(twoPlaces) != nil)
        #expect(FX.ExchangeRateOf<Ether, Currencies.GBP>(threePlaces) == nil)
    }

    @Test("A positive rate builds")
    func positiveRateBuilds() throws {
        let rate = try #require(Rate(string: "0.8765262907"))

        #expect(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(rate) != nil)
    }

    @Test("A zero or negative rate is not an exchange rate")
    func nonPositiveIsNil() {
        #expect(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(.percent(0)) == nil)
        #expect(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(.percent(-1)) == nil)
    }

    @Test("A rate that overflows once rescaled between very different currency scales returns nil")
    func extremeScaleDifferenceReturnsNil() throws {
        let rate = try #require(Rate(string: "1000"))

        #expect(FX.ExchangeRateOf<LowPrecision, HighPrecision>(rate) == nil)
    }

    @Test("An ordinary rate between currencies of different scales still builds")
    func ordinaryScaleDifferenceStillBuilds() throws {
        let rate = try #require(Rate(string: "149.5"))

        #expect(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>(rate) != nil)
    }

    @Test("Applying a margin takes the spread off the mid rate")
    func applyingMargin() throws {
        let midRate = try #require(Rate(string: "1"))
        let mid = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(midRate))
        let margin = try #require(FX.Margin(.basisPoints(5)))                                          // 0.0005
        let expectedRate = try #require(Rate(string: "0.9995"))

        let customer = try mid.applyingMargin(margin)
        let expected = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(expectedRate))

        #expect(customer == expected)
    }

    @Test("A zero margin leaves the rate unchanged")
    func zeroMarginIsIdentity() throws {
        let midRate = try #require(Rate(string: "0.87"))
        let mid = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(midRate))
        let noMargin = try #require(FX.Margin(.percent(0)))

        #expect(try mid.applyingMargin(noMargin) == mid)
    }

    // The smallest rate less 60% is 0.4 of the smallest step, which rounds to zero.
    @Test("A margin that would round the customer rate to zero throws")
    func marginRoundingToZeroThrows() throws {
        let smallestRate = try #require(Rate(string: "0.000000000000000001"))
        let mid = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(smallestRate))
        let margin = try #require(FX.Margin(.percent(60)))

        #expect(throws: FX.ExchangeError<Never>.roundsToZero) {
            try mid.applyingMargin(margin)
        }
    }

    @Test("A typed rate's error is switched over with no case for a currency mismatch")
    func typedErrorNeedsNoMismatchCase() throws {
        let smallest = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.000000000000000001"))
        let margin = try #require(FX.Margin(.percent(60)))

        do throws(FX.ExchangeError<Never>) {
            _ = try smallest.applyingMargin(margin)
            Issue.record("Expected the customer rate to round to zero")
        } catch {
            switch error {
            case .overflow:
                Issue.record("Expected roundsToZero, not overflow")
            case .roundsToZero:
                break
            }
        }
    }

    @Test("Crossing two rates composes them through the shared currency")
    func crossing() throws {
        let eurUsdRate = try #require(Rate(string: "1.1"))
        let usdGbpRate = try #require(Rate(string: "0.8"))
        let expectedRate = try #require(Rate(string: "0.88"))

        let eurUsd = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.USD>(eurUsdRate))
        let usdGbp = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.GBP>(usdGbpRate))

        let eurGbp = try eurUsd.crossed(with: usdGbp)
        let expected = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>(expectedRate))

        #expect(eurGbp == expected)
    }

    @Test("Crossing two rates whose product is too large throws")
    func crossingPastTheLargestRateThrows() throws {
        let largeRate = try #require(Rate(string: "1000000000000"))                                    // 10¹²
        let eurUsd = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.USD>(largeRate))
        let usdGbp = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.GBP>(largeRate))

        #expect(throws: FX.ExchangeError<Never>.overflow) {
            try eurUsd.crossed(with: usdGbp)
        }
    }

    @Test("Crossing two rates whose product rounds to zero throws")
    func crossingToZeroThrows() throws {
        let smallRate = try #require(Rate(string: "0.0000000001"))                                     // 10⁻¹⁰
        let eurUsd = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.USD>(smallRate))
        let usdGbp = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.GBP>(smallRate))

        #expect(throws: FX.ExchangeError<Never>.roundsToZero) {
            try eurUsd.crossed(with: usdGbp)
        }
    }

    @Test("Equal rates hash alike, however they were reached, and different rates stay apart")
    func hashing() throws {
        let quoted = try #require(FX.ExchangeRateOf<Currencies.GBP, Currencies.EUR>("1.25"))
        let inverted = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.8")).inverted()
        let other = try #require(FX.ExchangeRateOf<Currencies.GBP, Currencies.EUR>("1.2"))

        #expect(quoted.hashValue == inverted.hashValue)
        #expect(Set([quoted, inverted, other]).count == 2)
    }

    @Test("Inverting a rate gives the rate the other way")
    func inverting() throws {
        let eurGbp = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.8"))
        let expected = try #require(FX.ExchangeRateOf<Currencies.GBP, Currencies.EUR>("1.25"))

        #expect(try eurGbp.inverted() == expected)
    }

    @Test("Inverting a rate between currencies of different scales quotes it per major unit")
    func invertingAcrossScales() throws {
        let usdJpy = try #require(FX.ExchangeRateOf<Currencies.USD, Currencies.JPY>("125"))
        let expected = try #require(FX.ExchangeRateOf<Currencies.JPY, Currencies.USD>("0.008"))

        #expect(try usdJpy.inverted() == expected)
    }

    @Test("An inverse that needs more places than a rate keeps is rounded to the nearest")
    func invertingRounds() throws {
        let eurGbp = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("3"))
        let oneThird = try #require(Rate(string: "1/3"))
        let expected = try #require(FX.ExchangeRateOf<Currencies.GBP, Currencies.EUR>(oneThird))

        #expect(try eurGbp.inverted() == expected)
    }

    @Test("Inverting the smallest rate gives a large rate rather than overflowing")
    func invertingTheSmallestRate() throws {
        let smallest = try #require(FX.ExchangeRateOf<Currencies.EUR, Currencies.GBP>("0.000000000000000001"))
        let expected = try #require(FX.ExchangeRateOf<Currencies.GBP, Currencies.EUR>("1000000000000000000"))

        #expect(try smallest.inverted() == expected)
    }

    // ¥1 = $10¹⁷ is 10¹⁹ cents a yen, whose inverse, 10⁻¹⁹ yen a cent, is a tenth of the smallest step.
    @Test("Inverting a rate whose inverse rounds to zero throws")
    func invertingToZeroThrows() throws {
        let huge = try #require(FX.ExchangeRateOf<Currencies.JPY, Currencies.USD>("100000000000000000"))

        #expect(throws: FX.ExchangeError<Never>.roundsToZero) {
            try huge.inverted()
        }
    }
}

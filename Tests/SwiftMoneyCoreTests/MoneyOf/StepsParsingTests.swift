import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>
private typealias RuntimeStepsError = CurrencyCheckedError<StepsError<AnyCurrency>>

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

// The errors carry bounds but have no public initializer, so each is taken from the range builder
// that reports it.
private func invertedError(lower: GBP, upper: GBP) -> InvertedBoundsError<Currencies.GBP>? {
    do throws(InvertedBoundsError<Currencies.GBP>) {
        _ = try ClosedRange(checkedBounds: (lower: lower, upper: upper))
        return nil
    } catch {
        return error
    }
}

private func invertedError(lower: Money, upper: Money) -> InvertedBoundsError<AnyCurrency>? {
    do throws(CurrencyCheckedError<InvertedBoundsError<AnyCurrency>>) {
        _ = try lower...upper
        return nil
    } catch {
        guard case let .failure(inverted) = error else {
            return nil
        }
        return inverted
    }
}

private func tooManyStepsError() -> TooManyStepsError? {
    do throws(TooManyStepsError) {
        _ = try (GBP.min ... GBP.max).steps(by: .minorUnit)
        return nil
    } catch {
        return error
    }
}

@Suite("MoneyOf.Steps from untrusted bounds and step")
struct StepsParsingTests {

    @Test("Bounds and a raw step from a server build the steps a range and a stride would")
    func typedEqualsRangeSteps() throws {
        let parsed = try GBP.Steps(from: GBP(minorUnits: 10_00), through: GBP(minorUnits: 250_00), by: GBP(minorUnits: 100_00))
        let stepped = try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(100))

        #expect(parsed == stepped)
        #expect(parsed.map(\.minorUnits) == [10_00, 110_00, 210_00, 250_00])
    }

    @Test("A negative step walks down from the upper bound, and a yen or custom currency parses the same way")
    func negativeAndOtherCurrencies() throws {
        let down = try JPY.Steps(from: JPY(minorUnits: 0), through: JPY(minorUnits: 250), by: JPY(minorUnits: -100))
        let credits = try Credits.Steps(from: Credits(minorUnits: 0), through: Credits(minorUnits: 2_500), by: Credits(minorUnits: 1_000))

        #expect(down.map(\.minorUnits) == [250, 150, 50, 0])
        #expect(credits.map(\.minorUnits) == [0, 1_000, 2_000, 2_500])
    }

    @Test("Typed inverted bounds throw invertedBounds with both bounds")
    func typedInverted() throws {
        let inverted = try #require(invertedError(lower: GBP(minorUnits: 250_00), upper: GBP(minorUnits: 10_00)))

        #expect(throws: StepsError.invertedBounds(inverted)) {
            try GBP.Steps(from: GBP(minorUnits: 250_00), through: GBP(minorUnits: 10_00), by: GBP(minorUnits: 1_00))
        }
    }

    @Test("A typed zero step throws zeroStride; one too fine to count throws tooManySteps")
    func typedZeroAndTooMany() throws {
        let tooMany = try #require(tooManyStepsError())

        #expect(throws: StepsError<Currencies.GBP>.zeroStride) {
            try GBP.Steps(from: .zero, through: GBP(minorUnits: 1_00), by: .zero)
        }
        #expect(throws: StepsError<Currencies.GBP>.tooManySteps(tooMany)) {
            try GBP.Steps(from: .min, through: .max, by: GBP(minorUnits: 1))
        }
    }

    @Test("Typed parsing throws only StepsError, so a switch needs no mismatch branch")
    func typedThrowsExactly() {
        do throws(StepsError<Currencies.GBP>) {
            _ = try GBP.Steps(from: .min, through: .max, by: GBP(minorUnits: -1))
            Issue.record("Expected too many steps to throw")
        } catch {
            switch error {
            case .invertedBounds, .zeroStride:
                Issue.record("Expected too many steps, not \(error)")
            case .tooManySteps:
                break
            }
        }
    }

    @Test("Inverted bounds are reported before a zero step")
    func typedOrder() throws {
        let inverted = try #require(invertedError(lower: GBP(minorUnits: 2), upper: GBP(minorUnits: 1)))

        #expect(throws: StepsError.invertedBounds(inverted)) {
            try GBP.Steps(from: GBP(minorUnits: 2), through: GBP(minorUnits: 1), by: .zero)
        }
    }

    @Test("Runtime bounds and step in one currency build the steps a range and a stride would")
    func runtimeEqualsRangeSteps() throws {
        let parsed = try Money.Steps(from: pounds(10_00), through: pounds(250_00), by: pounds(-100_00))
        let stepped = try (pounds(10_00)...pounds(250_00)).steps(by: #require(.majorUnits(-100, of: .gbp)))

        #expect(parsed == stepped)
        #expect(parsed == Money.Steps(try GBP.Steps(from: GBP(minorUnits: 10_00), through: GBP(minorUnits: 250_00), by: GBP(minorUnits: -100_00))))
    }

    @Test("An upper bound, or else a step, in another currency throws a mismatch, the lower bound's first")
    func runtimeMismatch() {
        let yen = Money(minorUnits: 100, currency: .jpy)
        let euros = Money(minorUnits: 100, currency: .eur)

        #expect(throws: RuntimeStepsError.currencyMismatch(lhs: .gbp, rhs: .jpy)) {
            try Money.Steps(from: pounds(0), through: yen, by: pounds(1_00))
        }
        #expect(throws: RuntimeStepsError.currencyMismatch(lhs: .gbp, rhs: .jpy)) {
            try Money.Steps(from: pounds(0), through: pounds(5_00), by: yen)
        }
        #expect(throws: RuntimeStepsError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try Money.Steps(from: pounds(5_00), through: euros, by: yen)
        }
    }

    @Test("A mismatched step is reported before inverted bounds; inverted before a zero step")
    func runtimeOrder() throws {
        let inverted = try #require(invertedError(lower: pounds(5_00), upper: pounds(0)))

        #expect(throws: RuntimeStepsError.currencyMismatch(lhs: .gbp, rhs: .jpy)) {
            try Money.Steps(from: pounds(5_00), through: pounds(0), by: Money(minorUnits: 0, currency: .jpy))
        }
        #expect(throws: RuntimeStepsError.failure(.invertedBounds(inverted))) {
            try Money.Steps(from: pounds(5_00), through: pounds(0), by: pounds(0))
        }
    }

    @Test("A runtime zero step or one too fine to count throws a failure naming it")
    func runtimeZeroAndTooMany() throws {
        let tooMany = try #require(tooManyStepsError())
        let lowest = Money(minorUnits: Int64.min, currency: .gbp)
        let highest = Money(minorUnits: Int64.max, currency: .gbp)

        #expect(throws: RuntimeStepsError.failure(.zeroStride)) {
            try Money.Steps(from: pounds(0), through: pounds(1_00), by: pounds(0))
        }
        #expect(throws: RuntimeStepsError.failure(.tooManySteps(tooMany))) {
            try Money.Steps(from: lowest, through: highest, by: pounds(1))
        }
    }

    @Test("A custom currency at another scale is a mismatch")
    func runtimeScaleMismatch() {
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let fine = Millicredits.currency

        #expect(throws: RuntimeStepsError.currencyMismatch(lhs: fine, rhs: coarse)) {
            try Money.Steps(
                from: Money(minorUnits: 0, currency: fine),
                through: Money(minorUnits: 10, currency: coarse),
                by: Money(minorUnits: 1, currency: fine)
            )
        }
    }
}

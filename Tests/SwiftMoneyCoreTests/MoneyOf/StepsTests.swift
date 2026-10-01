import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private func typedStride(_ minorUnits: Int64) throws -> GBP.Stride {
    try #require(GBP.Stride(exactly: GBP(minorUnits: minorUnits)))
}

@Suite("MoneyOf.Steps")
struct StepsTests {

    @Test("£10 to £250 by £100 is £10, £110, £210 and then £250, ending on the far bound")
    func endsOnTheFarBound() throws {
        let steps = try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(100))

        #expect(steps.map(\.minorUnits) == [10_00, 110_00, 210_00, 250_00])
        #expect(steps.count == 4)
    }

    @Test("A span that is an exact multiple of the stride holds the far bound once")
    func exactMultipleHasNoDuplicate() throws {
        let steps = try (JPY(minorUnits: 0) ... JPY(minorUnits: 300)).steps(by: .minorUnits(100))

        #expect(steps.map(\.minorUnits) == [0, 100, 200, 300])
    }

    @Test("A stride longer than the span gives both bounds")
    func strideLongerThanSpan() throws {
        let steps = try (GBP(minorUnits: 10) ... GBP(minorUnits: 250)).steps(by: .majorUnits(5))

        #expect(steps.map(\.minorUnits) == [10, 250])
    }

    @Test("Equal bounds give one step, whichever way the stride points")
    func equalBoundsGiveOne() throws {
        let five = Credits(minorUnits: 5_000)

        #expect(Array(try (five ... five).steps(by: .majorUnit)) == [five])
        #expect(Array(try (five ... five).steps(by: .majorUnits(-3))) == [five])
    }

    @Test("A negative stride starts on the upper bound, counts down and ends on the lower")
    func negativeCountsDown() throws {
        let steps = try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(-100))

        #expect(steps.map(\.minorUnits) == [250_00, 150_00, 50_00, 10_00])
    }

    @Test("Negative bounds step as positive ones do")
    func negativeBounds() throws {
        let steps = try (GBP(minorUnits: -250) ... GBP(minorUnits: -10)).steps(by: .minorUnits(100))

        #expect(steps.map(\.minorUnits) == [-250, -150, -50, -10])
    }

    @Test("The whole width of an amount by 2⁶² has five steps, both ways, though offsets overflow Int64")
    func wholeWidth() throws {
        let quarter: Int64 = 1 << 62
        let up = try (GBP.min ... GBP.max).steps(by: typedStride(quarter))
        let down = try (GBP.min ... GBP.max).steps(by: typedStride(-quarter))

        #expect(up.map(\.minorUnits) == [Int64.min, Int64.min + quarter, 0, quarter, Int64.max])
        #expect(down.map(\.minorUnits) == [Int64.max, Int64.max - quarter, -1, -1 - quarter, Int64.min])
    }

    @Test("The stride is the requested one, or the span when that is shorter, in the requested direction")
    func canonicalStride() throws {
        let range = GBP(minorUnits: 10) ... GBP(minorUnits: 250)

        #expect(try range.steps(by: .minorUnits(100)).stride == .minorUnits(100))
        #expect(try range.steps(by: .minorUnits(-500)).stride == .minorUnits(-240))
        #expect(try (GBP.zero ... .zero).steps(by: .majorUnits(-5)).stride == .minorUnit)
        #expect(try (GBP.zero ... .zero).steps(by: .majorUnit).stride == .minorUnit)
    }

    @Test("A single step built by 1p equals it built by −£5, hash included: one step has no direction")
    func singleStepIgnoresDirection() throws {
        let three = GBP(minorUnits: 3_00)
        let up = try (three ... three).steps(by: .minorUnit)
        let down = try (three ... three).steps(by: .majorUnits(-5))
        let runtimeDown = try (pounds(3_00)...pounds(3_00)).steps(by: #require(.majorUnits(-5, of: .gbp)))

        #expect(up == down)
        #expect(up.hashValue == down.hashValue)
        #expect(runtimeDown == Money.Steps(up))
        #expect(runtimeDown.hashValue == Money.Steps(up).hashValue)
    }

    @Test("£0 to £1,000,000 by 1p has 100,000,001 steps, the last £1,000,000, without walking them")
    func largeCount() throws {
        let steps = try (GBP.zero ... GBP(minorUnits: 1_000_000_00)).steps(by: .minorUnit)

        #expect(steps.count == 100_000_001)
        #expect(steps.last == GBP(minorUnits: 1_000_000_00))
        #expect(steps[steps.index(before: steps.endIndex)] == GBP(minorUnits: 1_000_000_00))
    }

    @Test("A count that Int can hold builds; one more throws tooManySteps")
    func tooManySteps() throws {
        let largest = Int64(Int.max)

        #expect(try (GBP.zero ... GBP(minorUnits: largest - 1)).steps(by: .minorUnit).count == Int.max)
        #expect(throws: MoneyStepsParsingError<Currencies.GBP>.tooManySteps) {
            try (GBP.zero ... GBP(minorUnits: largest)).steps(by: .minorUnit)
        }
        #expect(throws: MoneyStepsParsingError<Currencies.GBP>.tooManySteps) {
            try (GBP.min ... GBP.max).steps(by: .minorUnits(-1))
        }
    }

    @Test("Typed steps throw MoneyStepsParsingError, so a switch needs no mismatch branch")
    func typedThrowsExactly() {
        // The check is the compiler's: this `do` compiles only if `steps(by:)` throws exactly
        // `MoneyStepsParsingError<Currencies.GBP>`.
        do throws(MoneyStepsParsingError<Currencies.GBP>) {
            _ = try (GBP.min ... GBP.max).steps(by: .minorUnit)
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

    @Test("Runtime steps are the typed ones, in the range's currency")
    func runtimeMatchesTyped() throws {
        let runtime = try (pounds(10_00)...pounds(250_00)).steps(by: #require(.majorUnits(-100, of: .gbp)))
        let typed = try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(-100))

        #expect(Array(runtime) == typed.map { Money($0) })
        #expect(runtime.stride == Money.Stride(typed.stride))
    }

    @Test("A yen range with a stride in pence throws a mismatch, the range's currency first")
    func runtimeMismatch() throws {
        let yen = try Money(minorUnits: 0, currency: .jpy)...Money(minorUnits: 1_000, currency: .jpy)

        #expect(throws: CurrencyCheckedError<MoneyStepsParsingError<AnyCurrency>>.currencyMismatch(lhs: .jpy, rhs: .gbp)) {
            try yen.steps(by: .minorUnits(1_00, of: .gbp))
        }
    }

    @Test("Runtime steps too many to count throw a failure")
    func runtimeTooMany() throws {
        let range = try Money(minorUnits: Int64.min, currency: .gbp)...Money(minorUnits: Int64.max, currency: .gbp)

        do throws(CurrencyCheckedError<MoneyStepsParsingError<AnyCurrency>>) {
            _ = try range.steps(by: .minorUnit(of: .gbp))
            Issue.record("Expected too many steps to throw")
        } catch {
            switch error {
            case .failure(.tooManySteps):
                break
            case .currencyMismatch, .failure(.invertedBounds), .failure(.zeroStride):
                Issue.record("Expected too many steps, not \(error)")
            }
        }
    }

    @Test("Typed steps become runtime ones and back, keeping every step")
    func conversions() throws {
        let typed = try (Credits(minorUnits: -5_000) ... Credits(minorUnits: 7_500)).steps(by: .majorUnits(2))
        let runtime = Money.Steps(typed)

        #expect(Array(runtime) == typed.map { Money($0) })
        #expect(runtime.stride == Money.Stride(typed.stride))
        #expect(try MoneyOf<Millicredits>.Steps(runtime) == typed)
    }

    @Test("Runtime steps in another currency, or at another scale, throw a mismatch naming both")
    func conversionMismatch() throws {
        let yen = Money.Steps(try (JPY(minorUnits: 0) ... JPY(minorUnits: 10)).steps(by: .minorUnit))
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let coarseCredits = try (Money(minorUnits: 0, currency: coarse)...Money(minorUnits: 10, currency: coarse))
            .steps(by: .minorUnit(of: coarse))

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)) { try GBP.Steps(yen) }
        #expect(throws: MoneyError.currencyMismatch(lhs: Millicredits.currency, rhs: coarse)) {
            try Credits.Steps(coarseCredits)
        }
    }

    @Test("£0.10 to £2.50 by 240p equals it by 500p, hash included: the same steps")
    func equalStepsAreEqual() throws {
        let range = GBP(minorUnits: 10) ... GBP(minorUnits: 250)
        let exact = try range.steps(by: .minorUnits(240))
        let longer = try range.steps(by: .minorUnits(500))
        let runtime = try (pounds(10)...pounds(250)).steps(by: .minorUnits(500, of: .gbp))

        #expect(exact == longer)
        #expect(exact.hashValue == longer.hashValue)
        #expect(runtime == Money.Steps(exact))
        #expect(runtime.hashValue == Money.Steps(exact).hashValue)
    }

    @Test("Different steps, directions or currencies are unequal")
    func differentStepsAreUnequal() throws {
        let range = try pounds(1_00)...pounds(2_00)
        let byTen = try range.steps(by: .minorUnits(10, of: .gbp))
        let euros = try (Money(minorUnits: 1_00, currency: .eur)...Money(minorUnits: 2_00, currency: .eur))
            .steps(by: .minorUnits(10, of: .eur))

        #expect(byTen != (try range.steps(by: .minorUnits(20, of: .gbp))))
        #expect(byTen != (try range.steps(by: .minorUnits(-10, of: .gbp))))
        #expect(byTen != euros)
        #expect(Array(byTen).map(\.minorUnits) == Array(euros).map(\.minorUnits))
    }
}

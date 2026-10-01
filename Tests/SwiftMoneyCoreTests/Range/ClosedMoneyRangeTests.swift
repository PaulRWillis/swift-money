import SwiftMoneyCore
import Testing

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private func euros(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .eur)
}

private typealias BuildError = MoneyRangeParsingError<AnyCurrency>

@Suite("ClosedMoneyRange")
struct ClosedMoneyRangeTests {

    @Test("Bounds in one currency build a range holding them")
    func buildsFromSameCurrency() throws {
        let range = try pounds(10_00)...pounds(250_00)

        #expect(range.lowerBound == pounds(10_00))
        #expect(range.upperBound == pounds(250_00))
        #expect(range.currency == .gbp)
        #expect(range.isEmpty == false)
    }

    @Test("Bounds in two currencies throw a mismatch with the upper bound's currency")
    func mismatchThrows() {
        #expect(throws: BuildError.currencyMismatch(.eur)) {
            try pounds(10_00)...euros(250_00)
        }
    }

    @Test("A switch over a build error binds the upper bound's currency")
    func mismatchBindsCurrency() {
        do throws(BuildError) {
            _ = try pounds(10_00)...euros(250_00)
            Issue.record("Expected a mismatch to throw")
        } catch {
            switch error {
            case .invertedBounds:
                Issue.record("Expected a mismatch, not inverted bounds")
            case let .currencyMismatch(currency):
                #expect(currency == .eur)
            }
        }
    }

    @Test("Inverted bounds throw invertedBounds with both bounds as given")
    func invertedThrows() {
        #expect(throws: BuildError.invertedBounds(lowerBound: pounds(250_00), upperBound: pounds(10_00))) {
            try pounds(250_00)...pounds(10_00)
        }
    }

    @Test("Inverted bounds in two currencies report the mismatch")
    func mismatchBeforeInverted() {
        #expect(throws: BuildError.currencyMismatch(.eur)) {
            try pounds(250_00)...euros(10_00)
        }
    }

    @Test("Equal bounds build a range holding that one amount")
    func equalBounds() throws {
        let range = try pounds(5_00)...pounds(5_00)

        #expect(try range.contains(pounds(5_00)))
        #expect(try range.contains(pounds(5_01)) == false)
        #expect(range.isEmpty == false)
    }

    @Test("init(checkedBounds:) builds the same range as the operator")
    func checkedBoundsEqualsOperator() throws {
        let checked = try ClosedMoneyRange(checkedBounds: (lower: pounds(1_00), upper: pounds(2_00)))

        #expect(try checked == pounds(1_00)...pounds(2_00))
    }

    @Test("init(checkedBounds:) throws as the operator does")
    func checkedBoundsThrows() {
        #expect(throws: BuildError.invertedBounds(lowerBound: pounds(2_00), upperBound: pounds(1_00))) {
            try ClosedMoneyRange(checkedBounds: (lower: pounds(2_00), upper: pounds(1_00)))
        }
        #expect(throws: BuildError.currencyMismatch(.gbp)) {
            try ClosedMoneyRange(checkedBounds: (lower: euros(1_00), upper: pounds(2_00)))
        }
    }

    @Test("A typed range becomes the runtime range the operator builds")
    func typedToRuntime() throws {
        let typed = GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)

        #expect(try ClosedMoneyRange(typed) == pounds(10_00)...pounds(250_00))
        #expect(ClosedMoneyRange(JPY(minorUnits: 1) ... JPY(minorUnits: 9)).currency == .jpy)
    }

    @Test("Contains both bounds and what lies between them")
    func containsBothEnds() throws {
        let range = try pounds(10_00)...pounds(250_00)

        #expect(try range.contains(pounds(10_00)))
        #expect(try range.contains(pounds(250_00)))
        #expect(try range.contains(pounds(100_00)))
    }

    @Test("Does not contain amounts just outside its bounds")
    func excludesOutside() throws {
        let range = try pounds(10_00)...pounds(250_00)

        #expect(try range.contains(pounds(9_99)) == false)
        #expect(try range.contains(pounds(250_01)) == false)
    }

    @Test("Asking about an amount in another currency throws a mismatch, range's currency first")
    func containsMismatch() throws {
        let range = try pounds(10_00)...pounds(250_00)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try range.contains(euros(100_00))
        }
    }

    @Test("A range in a custom currency differs from one at the same code and another scale")
    func customScale() throws {
        let fine = Millicredits.currency
        let coarse = customCurrency(code: "MCR", unitScale: 1)
        let fineRange = try Money(minorUnits: 1, currency: fine)...Money(minorUnits: 2, currency: fine)
        let coarseRange = try Money(minorUnits: 1, currency: coarse)...Money(minorUnits: 2, currency: coarse)

        #expect(fineRange != coarseRange)
        #expect(throws: MoneyError.currencyMismatch(lhs: fine, rhs: coarse)) {
            try fineRange.contains(Money(minorUnits: 1, currency: coarse))
        }
    }

    @Test("Equal ranges hash equally, and the same bounds in another currency are unequal")
    func hashAndEquality() throws {
        let first = try pounds(1_00)...pounds(2_00)
        let second = try pounds(1_00)...pounds(2_00)

        #expect(first == second)
        #expect(first.hashValue == second.hashValue)
        #expect(try first != euros(1_00)...euros(2_00))
    }

    @Test("Describes itself as the standard library writes a closed range")
    func descriptions() throws {
        let sterling = try pounds(10_00)...pounds(250_00)
        let yen = try Money(minorUnits: 10, currency: .jpy)...Money(minorUnits: 250, currency: .jpy)

        #expect(sterling.description == "GBP 10.00...GBP 250.00")
        #expect(sterling.debugDescription == "ClosedMoneyRange(GBP 10.00...GBP 250.00)")
        #expect(yen.description == "JPY 10...JPY 250")
        #expect(yen.debugDescription == "ClosedMoneyRange(JPY 10...JPY 250)")
    }

    @Test("A typed range converted to a runtime one answers contains for a runtime amount")
    func typedInterop() throws {
        let limits = ClosedMoneyRange(GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00))

        #expect(try limits.contains(pounds(100_00)))
        #expect(try limits.contains(pounds(250_01)) == false)
    }

    @Test("A range check works as a switch case through a where clause")
    func switchPattern() throws {
        let limits = try pounds(10_00)...pounds(250_00)

        func band(_ amount: Money) throws -> String {
            switch amount {
            case _ where try limits.contains(amount):
                "within"
            default:
                "outside"
            }
        }

        #expect(try band(pounds(100_00)) == "within")
        #expect(try band(pounds(1_00)) == "outside")
    }
}

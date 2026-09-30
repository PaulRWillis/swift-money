import SwiftMoneyCore
import Testing

@Suite("MoneyError Tests")
struct MoneyErrorTests {

    @Test("A mismatch names both currencies")
    func mismatchNamesBothCurrencies() throws {
        let error = MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)

        guard case let .currencyMismatch(lhs, rhs) = error else {
            Issue.record("Expected a currency mismatch")
            return
        }

        #expect(lhs == .gbp)
        #expect(rhs == .eur)
    }

    @Test("Mismatches of the same pair are equal")
    func equalMismatches() {
        #expect(
            MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)
                == MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)
        )
    }

    @Test("Equal mismatches hash equally, so errors can be collected in a set")
    func equalMismatchesHashEqually() {
        let errors: Set<MoneyError> = [
            .currencyMismatch(lhs: .gbp, rhs: .eur),
            .currencyMismatch(lhs: .gbp, rhs: .eur),
            .currencyMismatch(lhs: .eur, rhs: .gbp),
        ]

        #expect(errors.count == 2)
    }

    @Test("A mismatch is directional, so swapping the currencies is a different error")
    func mismatchIsDirectional() {
        #expect(
            MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)
                != MoneyError.currencyMismatch(lhs: .eur, rhs: .gbp)
        )
    }
}

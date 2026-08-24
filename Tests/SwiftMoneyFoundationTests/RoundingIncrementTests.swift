import SwiftMoneyFoundation
import Testing

@Suite("Rounding Increment Tests")
struct RoundingIncrementTests {
    // MARK: - Exact Initialization

    @Test("A value of one creates an increment")
    func acceptsOne() throws {
        let increment = try #require(RoundingIncrement(exactly: 1))

        #expect(Int64(increment) == 1)
    }

    @Test("A value above one creates an increment")
    func acceptsFive() throws {
        let increment = try #require(RoundingIncrement(exactly: 5))

        #expect(Int64(increment) == 5)
    }

    @Test("Zero is refused")
    func refusesZero() {
        #expect(RoundingIncrement(exactly: 0) == nil)
    }

    @Test("A negative value is refused")
    func refusesNegative() {
        #expect(RoundingIncrement(exactly: -5) == nil)
    }

    // MARK: - Literals

    @Test("A valid integer literal creates an increment")
    func validLiteral() throws {
        let increment: RoundingIncrement = 25

        #expect(increment == (try #require(RoundingIncrement(exactly: 25))))
    }

    @Test("A zero literal traps")
    func zeroLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let increment: RoundingIncrement = 0
            blackHole(increment)
        }
    }

    @Test("A negative literal traps")
    func negativeLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let increment: RoundingIncrement = -5
            blackHole(increment)
        }
    }

    // The failable initializer is labeled because an unlabeled one would be unreachable: with
    // ExpressibleByIntegerLiteral present, `RoundingIncrement(0)` always resolves to the literal
    // initializer, which traps rather than returning nil. Same trap as PartCount and CurrencyCode.
    @Test("The unlabeled call form is the trapping literal, not the failable initializer")
    func unlabeledFormIsTheLiteral() async {
        await #expect(processExitsWith: .failure) {
            blackHole(RoundingIncrement(0))
        }
    }

    // MARK: - Conversion

    @Test("An increment converts back to the integer it was built from")
    func convertsToInt64() throws {
        let increment = try #require(RoundingIncrement(exactly: 25))

        #expect(Int64(increment) == 25)
    }
}

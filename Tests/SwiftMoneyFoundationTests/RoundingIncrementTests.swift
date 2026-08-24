import Foundation
import SwiftMoneyFoundation
import Testing

@Suite("Rounding Increment Tests")
struct RoundingIncrementTests {

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

    @Test("A valid integer literal creates an increment")
    func acceptsAValidLiteral() throws {
        let increment: RoundingIncrement = 25

        #expect(increment == (try #require(RoundingIncrement(exactly: 25))))
    }

    // Two tests rather than one parameterized over [0, -5]: a capture clause in an exit-test
    // closure is a newer swift-testing feature, and CI's pinned toolchain refuses it.
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

    @Test("An increment converts back to the integer it was built from")
    func convertsToInt64() throws {
        let increment = try #require(RoundingIncrement(exactly: 25))

        #expect(Int64(increment) == 25)
    }

    @Test("An increment round-trips through JSON")
    func roundTripsThroughJSON() throws {
        let increment = try #require(RoundingIncrement(exactly: 25))
        let encoded = try JSONEncoder().encode([increment])
        let decoded = try JSONDecoder().decode([RoundingIncrement].self, from: encoded)

        #expect(decoded == [increment])
    }

    @Test("An increment encodes as its bare number")
    func encodesAsBareNumber() throws {
        let increment = try #require(RoundingIncrement(exactly: 25))
        let encoded = try JSONEncoder().encode([increment])

        #expect(String(decoding: encoded, as: UTF8.self) == "[25]")
    }

    @Test("A decoded increment below one throws", arguments: [0, -5])
    func refusesADecodedValueBelowOne(value: Int64) {
        let data = Data("[\(value)]".utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode([RoundingIncrement].self, from: data)
        }
    }
}

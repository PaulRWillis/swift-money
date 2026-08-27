import SwiftMoneyCore
import Testing

@Suite("UnitScale Tests")
struct UnitScaleTests {

    @Test(
        "A value with an exact decimal form is accepted",
        arguments: [
            1,                          // JPY: no subunit
            5,                          // MRU, MGA: the only non-decimal circulating currencies
            100,                        // GBP, EUR: the common case
            256,                        // US Treasury bonds, quoted in 256ths
            1_000,                      // BHD, KWD: three decimal places
            100_000_000,                // BTC: satoshis
            1_000_000_000_000_000_000,  // eighteen places, the finest a scale reaches
        ]
    )
    func acceptsValuesWithAnExactDecimalForm(_ raw: Int64) throws {
        let scale = try #require(UnitScale(exactly: raw))

        #expect(Int64(scale) == raw)
    }

    @Test(
        "Zero and negative values are rejected",
        arguments: [0, -1, -100, Int64.min]
    )
    func rejectsNonPositiveValues(_ raw: Int64) {
        #expect(UnitScale(exactly: raw) == nil)
    }

    @Test(
        "A value with no exact decimal form is rejected",
        arguments: [
            3,          // a third of a unit is 0.333…
            12,         // shillings of pence
            60,         // keeps a 3 even though it divides by 5
            240,        // pre-decimal GBP: 20 shillings of 12 pence
            1 << 30,    // 2 ^ 30: thirty places, past the eighteen a scale is allowed
            Int64.max,
        ] as [Int64]
    )
    func rejectsValuesWithoutAnExactDecimalForm(_ raw: Int64) {
        #expect(UnitScale(exactly: raw) == nil)
    }

    @Test(
        "A scale reports how many places write one of its smallest units",
        arguments: [
            (1, 0),
            (5, 1),
            (100, 2),
            (256, 8),
            (100_000_000, 8),
            (1_000_000_000_000_000_000, 18),
        ] as [(Int64, Int)]
    )
    func reportsItsDecimalPlaces(_ raw: Int64, _ expected: Int) throws {
        let scale = try #require(UnitScale(exactly: raw))

        #expect(scale.decimalPlaces == expected)
    }

    @Test("Equal values are equal, different values are not")
    func equality() throws {
        let hundred = try #require(UnitScale(exactly: 100))
        let alsoHundred = try #require(UnitScale(exactly: 100))
        let one = try #require(UnitScale(exactly: 1))

        #expect(hundred == alsoHundred)
        #expect(hundred != one)
        #expect(Set([hundred, alsoHundred, one]).count == 2)
    }

    @Test("A valid integer literal creates a unit scale")
    func validLiteral() throws {
        let scale: UnitScale = 100

        #expect(scale == (try #require(UnitScale(exactly: 100))))
    }

    @Test("A zero literal traps")
    func zeroLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let scale: UnitScale = 0
            blackHole(scale)
        }
    }

    @Test("A negative literal traps")
    func negativeLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let scale: UnitScale = -1
            blackHole(scale)
        }
    }

    @Test("A literal with no exact decimal form traps")
    func nonDecimalLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let scale: UnitScale = 240
            blackHole(scale)
        }
    }

    @Test("A literal reaching past eighteen decimal places traps")
    func tooFineLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let scale: UnitScale = 1_073_741_824  // 2 ^ 30, so thirty decimal places
            blackHole(scale)
        }
    }

    // The failable initializer is labeled because an unlabeled one would be unreachable: with
    // ExpressibleByIntegerLiteral present, `UnitScale(0)` always resolves to the literal
    // initializer, which traps rather than returning nil. Same trap as PartCount and CurrencyCode.
    @Test("The unlabeled call form is the trapping literal, not the failable initializer")
    func unlabeledFormIsTheLiteral() async {
        await #expect(processExitsWith: .failure) {
            blackHole(UnitScale(0))
        }
    }
}

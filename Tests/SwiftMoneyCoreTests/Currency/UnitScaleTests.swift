import SwiftMoneyCore
import Testing

@Suite("UnitScale Tests")
struct UnitScaleTests {

    @Test(
        "A power of ten is accepted",
        arguments: [
            1,                          // JPY: no subunit
            10,                         // one decimal place
            100,                        // GBP, EUR: the common case
            1_000,                      // BHD, KWD: three decimal places
            10_000,                     // CLF, UYW: four places
            100_000_000,                // BTC: satoshis, eight places
            1_000_000_000_000_000_000,  // eighteen places, the finest a scale reaches
        ]
    )
    func acceptsPowersOfTen(_ raw: Int64) throws {
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
        "A value that is not a power of ten is rejected",
        arguments: [
            3,          // a third of a unit is 0.333…
            5,          // MRU, MGA subdivide by five, but ISO records them at 100
            8,          // an eighth is an exact decimal, but not a power of ten
            240,        // pre-decimal GBP: 20 shillings of 12 pence
            256,        // US Treasury 256ths
            1 << 30,    // 2 ^ 30: a power of two, not ten
            Int64.max,
        ] as [Int64]
    )
    func rejectsValuesThatAreNotPowersOfTen(_ raw: Int64) {
        #expect(UnitScale(exactly: raw) == nil)
    }

    @Test(
        "A scale reports how many places write one of its smallest units",
        arguments: [
            (1, 0),
            (10, 1),
            (100, 2),
            (1_000, 3),
            (100_000_000, 8),
            (1_000_000_000_000_000_000, 18),
        ] as [(Int64, Int)]
    )
    func reportsItsDecimalPlaces(_ raw: Int64, _ expected: Int) throws {
        let scale = try #require(UnitScale(exactly: raw))

        #expect(scale.decimalPlaces == expected)
    }

    @Test(
        "A scale is built from a number of decimal places",
        arguments: [
            (0, 1),
            (2, 100),
            (8, 100_000_000),
            (18, 1_000_000_000_000_000_000),
        ] as [(Int, Int64)]
    )
    func buildsFromDecimalPlaces(_ places: Int, _ expectedScale: Int64) throws {
        let scale = try #require(UnitScale(decimalPlaces: places))

        #expect(Int64(scale) == expectedScale)
        #expect(scale.decimalPlaces == places)
    }

    @Test(
        "A number of decimal places outside zero to eighteen is rejected",
        arguments: [-1, 19, 100]
    )
    func rejectsDecimalPlacesOutOfRange(_ places: Int) {
        #expect(UnitScale(decimalPlaces: places) == nil)
    }

    @Test("A scale from a value and from its places are the same")
    func exactAndDecimalPlacesAgree() throws {
        #expect(try #require(UnitScale(exactly: 100)) == (try #require(UnitScale(decimalPlaces: 2))))
        #expect(try #require(UnitScale(exactly: 1)) == (try #require(UnitScale(decimalPlaces: 0))))
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

    @Test("A literal that is not a power of ten traps")
    func nonPowerOfTenLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let scale: UnitScale = 240
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

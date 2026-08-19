import SwiftMoney
import Testing

@Suite("MinimalQuantization Tests")
struct MinimalQuantizationTests {

    // MARK: - Accepted

    @Test(
        "Any positive value is accepted",
        arguments: [
            1,            // JPY — no subunit
            5,            // MRU, MGA — the only non-decimal circulating currencies
            100,          // GBP, EUR — the common case
            240,          // pre-decimal GBP: 20 shillings of 12 pence
            1_000,        // BHD, KWD — three decimal places
            100_000_000,  // BTC — satoshis
            Int64.max,
        ]
    )
    func acceptsPositiveValues(_ raw: Int64) throws {
        let quantization = try #require(MinimalQuantization(exactly: raw))

        #expect(Int64(quantization) == raw)
    }

    // MARK: - Rejected

    @Test(
        "Zero and negative values are rejected",
        arguments: [0, -1, -100, Int64.min]
    )
    func rejectsNonPositiveValues(_ raw: Int64) {
        #expect(MinimalQuantization(exactly: raw) == nil)
    }

    // MARK: - Equality

    @Test("Equal values are equal, different values are not")
    func equality() throws {
        let hundred = try #require(MinimalQuantization(exactly: 100))
        let alsoHundred = try #require(MinimalQuantization(exactly: 100))
        let one = try #require(MinimalQuantization(exactly: 1))

        #expect(hundred == alsoHundred)
        #expect(hundred != one)
        #expect(Set([hundred, alsoHundred, one]).count == 2)
    }

    // MARK: - Literals

    @Test("A valid integer literal creates a quantization")
    func validLiteral() throws {
        let quantization: MinimalQuantization = 100

        #expect(quantization == (try #require(MinimalQuantization(exactly: 100))))
    }

    @Test("A zero literal traps")
    func zeroLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let quantization: MinimalQuantization = 0
            blackHole(quantization)
        }
    }

    @Test("A negative literal traps")
    func negativeLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let quantization: MinimalQuantization = -1
            blackHole(quantization)
        }
    }

    // The failable initializer is labelled because an unlabelled one would be unreachable: with
    // ExpressibleByIntegerLiteral present, `MinimalQuantization(0)` always resolves to the literal
    // initializer, which traps rather than returning nil. Same trap as PartCount and CurrencyCode.
    @Test("The unlabelled call form is the trapping literal, not the failable initializer")
    func unlabelledFormIsTheLiteral() async {
        await #expect(processExitsWith: .failure) {
            blackHole(MinimalQuantization(0))
        }
    }
}

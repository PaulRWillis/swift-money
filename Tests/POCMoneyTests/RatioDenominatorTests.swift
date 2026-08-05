import POCMoney
import Testing

@Suite("Ratio.Denominator Tests")
struct RatioDenominatorTests {

    @Test("Positive values are accepted", arguments: [1, 2, 40, 100, 1_000, Int64.max])
    func acceptsPositiveValues(_ raw: Int64) throws {
        let denominator = try #require(Ratio.Denominator(exactly: raw))

        #expect(Int64(denominator) == raw)
    }

    @Test("Zero and negative values are rejected", arguments: [0, -1, -40, Int64.min])
    func rejectsNonPositiveValues(_ raw: Int64) {
        #expect(Ratio.Denominator(exactly: raw) == nil)
    }

    @Test("Equal values are equal, different values are not")
    func equality() throws {
        let forty = try #require(Ratio.Denominator(exactly: 40))
        let alsoForty = try #require(Ratio.Denominator(exactly: 40))
        let hundred = try #require(Ratio.Denominator(exactly: 100))

        #expect(forty == alsoForty)
        #expect(forty != hundred)
        #expect(Set([forty, alsoForty, hundred]).count == 2)
    }

    @Test("A denominator describes itself as its value", arguments: [1, 40, Int64.max])
    func description(_ raw: Int64) throws {
        let denominator = try #require(Ratio.Denominator(exactly: raw))

        #expect(String(describing: denominator) == "\(raw)")
    }

    @Test("A valid integer literal creates a denominator")
    func validLiteral() throws {
        let denominator: Ratio.Denominator = 40

        #expect(denominator == (try #require(Ratio.Denominator(exactly: 40))))
    }

    @Test("A zero literal traps")
    func zeroLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let denominator: Ratio.Denominator = 0
            blackHole(denominator)
        }
    }

    @Test("A negative literal traps")
    func negativeLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            let denominator: Ratio.Denominator = -1
            blackHole(denominator)
        }
    }

    // The failable initializer is labelled because an unlabelled one would be unreachable: with
    // ExpressibleByIntegerLiteral present, `Ratio.Denominator(0)` always resolves to the literal
    // initializer, which traps rather than returning nil. Same trap as PartCount and CurrencyCode.
    @Test("The unlabelled call form is the trapping literal, not the failable initializer")
    func unlabelledFormIsTheLiteral() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Ratio.Denominator(0))
        }
    }
}

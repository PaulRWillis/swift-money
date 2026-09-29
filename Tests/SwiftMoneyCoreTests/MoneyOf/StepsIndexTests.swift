import SwiftMoneyCore
import Testing

@Suite("MoneyOf.Steps.Index")
struct StepsIndexTests {

    @Test("An integer literal is the position that many steps from the start")
    func literalIsAnOffset() throws {
        let steps = try (JPY(minorUnits: 0) ... JPY(minorUnits: 30)).steps(by: .minorUnits(10))
        let second: JPY.Steps.Index = 1

        #expect(steps[second] == JPY(minorUnits: 10))
        #expect(steps[0] == JPY(minorUnits: 0))
        #expect(steps[3] == JPY(minorUnits: 30))
        #expect(steps.index(after: second) == 2)
    }

    @Test("Indices order and hash by position")
    func orderAndHash() {
        let first: Money.Steps.Index = 0
        let again: Money.Steps.Index = 0
        let later: Money.Steps.Index = 7

        #expect(first < later)
        #expect(!(later < first))
        #expect(first == again)
        #expect(first.hashValue == again.hashValue)
        #expect(first != later)
    }

    @Test("A negative literal traps")
    func negativeLiteralTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(GBP.Steps.Index(integerLiteral: -1))
        }
    }
}

import SwiftMoney
import Testing

@Suite("Weighted Split Tests")
struct WeightedSplitTests {

    @Test("Weights that divide exactly give each part its exact share")
    func exactShares() {
        let parts = GBP(minorUnits: 100).split(by: [60, 30, 10])

        #expect(parts == [GBP(minorUnits: 60), GBP(minorUnits: 30), GBP(minorUnits: 10)])
    }

    @Test("Part order follows weight order")
    func partOrderFollowsWeightOrder() {
        let parts = GBP(minorUnits: 100).split(by: [10, 30, 60])

        #expect(parts == [GBP(minorUnits: 10), GBP(minorUnits: 30), GBP(minorUnits: 60)])
    }

    @Test("A zero amount gives every part zero")
    func zeroAmount() {
        let parts = GBP(minorUnits: 0).split(by: [60, 30, 10])

        #expect(parts == [GBP(minorUnits: 0), GBP(minorUnits: 0), GBP(minorUnits: 0)])
    }

    @Test("A single weight receives the whole amount")
    func singleWeight() {
        #expect(GBP(minorUnits: 4_99).split(by: [7]) == [GBP(minorUnits: 4_99)])
    }
}

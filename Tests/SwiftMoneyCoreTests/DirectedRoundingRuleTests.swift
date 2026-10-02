import SwiftMoneyCore
import Testing

// Each directed rule beside the rounding rule of the same name.
private let namesakes: [(directed: DirectedRoundingRule, rule: RoundingRule)] = [
    (.down, .down),
    (.up, .up),
    (.towardZero, .towardZero),
    (.awayFromZero, .awayFromZero),
]

@Suite("DirectedRoundingRule Tests")
struct DirectedRoundingRuleTests {

    @Test("A directed rule converts to the rounding rule of the same name", arguments: namesakes)
    func convertsToTheNamesake(_ pair: (directed: DirectedRoundingRule, rule: RoundingRule)) {
        #expect(RoundingRule(pair.directed) == pair.rule)
    }

    @Test("A rounding rule that names a direction parses to the directed rule of the same name", arguments: namesakes)
    func parsesTheNamesake(_ pair: (directed: DirectedRoundingRule, rule: RoundingRule)) {
        #expect(DirectedRoundingRule(pair.rule) == pair.directed)
    }

    @Test("A nearest rule names no direction", arguments: [RoundingRule.toNearestOrEven, .toNearestOrAwayFromZero])
    func nearestRuleIsNil(_ rule: RoundingRule) {
        #expect(DirectedRoundingRule(rule) == nil)
    }
}

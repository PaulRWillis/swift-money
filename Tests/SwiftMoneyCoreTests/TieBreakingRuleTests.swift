import SwiftMoneyCore
import Testing

// Each tie-break beside the nearest rounding rule that breaks a tie the same way.
private let namesakes: [(tie: TieBreakingRule, rule: RoundingRule)] = [
    (.even, .toNearestOrEven),
    (.awayFromZero, .toNearestOrAwayFromZero),
]

@Suite("TieBreakingRule Tests")
struct TieBreakingRuleTests {

    @Test("A tie-break converts to the nearest rule that breaks a tie the same way", arguments: namesakes)
    func convertsToTheNearestRule(_ pair: (tie: TieBreakingRule, rule: RoundingRule)) {
        #expect(RoundingRule(pair.tie) == pair.rule)
    }

    @Test("A nearest rule parses to the tie-break it uses", arguments: namesakes)
    func parsesTheNearestRule(_ pair: (tie: TieBreakingRule, rule: RoundingRule)) {
        #expect(TieBreakingRule(pair.rule) == pair.tie)
    }

    @Test("A rule that names a direction has no tie-break", arguments: [RoundingRule.down, .up, .towardZero, .awayFromZero])
    func directedRuleIsNil(_ rule: RoundingRule) {
        #expect(TieBreakingRule(rule) == nil)
    }
}

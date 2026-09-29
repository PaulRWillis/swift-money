import Foundation
import SwiftMoneyCore
import Testing

// `RoundingRule` was once the standard library's type, so data an app wrote then was written by
// Foundation's own conformance. This checks the library still reads it.
@Suite("RoundingRule compatibility")
struct RoundingRuleCompatibilityTests {

    @Test(
        "A rule Foundation wrote reads back as the rule of the same name",
        arguments: [
            (FloatingPointRoundingRule.toNearestOrAwayFromZero, RoundingRule.toNearestOrAwayFromZero),
            (.toNearestOrEven, .toNearestOrEven),
            (.up, .up),
            (.down, .down),
            (.towardZero, .towardZero),
            (.awayFromZero, .awayFromZero),
        ]
    )
    func readsWhatFoundationWrote(_ written: FloatingPointRoundingRule, _ expected: RoundingRule) throws {
        let data = try JSONEncoder().encode(written)

        #expect(try JSONDecoder().decode(RoundingRule.self, from: data) == expected)
    }
}

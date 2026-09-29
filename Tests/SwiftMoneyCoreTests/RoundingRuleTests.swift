import Foundation
import SwiftMoneyCore
import Testing

// Each rule beside the standard library's rule of the same name, and the integer Foundation writes for it.
private let namesakes: [(rule: RoundingRule, standard: FloatingPointRoundingRule, coded: String)] = [
    (.toNearestOrAwayFromZero, .toNearestOrAwayFromZero, "0"),
    (.toNearestOrEven, .toNearestOrEven, "1"),
    (.up, .up, "2"),
    (.down, .down, "3"),
    (.towardZero, .towardZero, "4"),
    (.awayFromZero, .awayFromZero, "5"),
]

@Suite("RoundingRule Tests")
struct RoundingRuleTests {

    @Test("A standard-library rule parses to the rule of the same name", arguments: namesakes)
    func parsesTheNamesake(_ pair: (rule: RoundingRule, standard: FloatingPointRoundingRule, coded: String)) {
        #expect(RoundingRule(pair.standard) == pair.rule)
    }

    @Test("A rule converts to the standard-library rule of the same name", arguments: namesakes)
    func convertsToTheNamesake(_ pair: (rule: RoundingRule, standard: FloatingPointRoundingRule, coded: String)) {
        #expect(FloatingPointRoundingRule(pair.rule) == pair.standard)
    }

    @Test("A rule encodes as the integer Foundation writes for it", arguments: namesakes)
    func encodesAsFoundationDoes(_ pair: (rule: RoundingRule, standard: FloatingPointRoundingRule, coded: String)) throws {
        let data = try JSONEncoder().encode(pair.rule)

        #expect(String(decoding: data, as: UTF8.self) == pair.coded)
    }

    @Test("A rule decodes from the integer Foundation writes for it", arguments: namesakes)
    func decodesAsFoundationDoes(_ pair: (rule: RoundingRule, standard: FloatingPointRoundingRule, coded: String)) throws {
        let decoded = try JSONDecoder().decode(RoundingRule.self, from: Data(pair.coded.utf8))

        #expect(decoded == pair.rule)
    }

    @Test("An integer that names no rule does not decode", arguments: ["6", "-1"])
    func rejectsAnUnknownInteger(_ text: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RoundingRule.self, from: Data(text.utf8))
        }
    }

    @Test("A rule's name does not decode, since Foundation never wrote one")
    func rejectsAName() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RoundingRule.self, from: Data(#""up""#.utf8))
        }
    }
}

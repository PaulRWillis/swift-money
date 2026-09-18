import SwiftMoneyLocalization
import Testing

@Suite("PluralOperand Tests")
struct PluralOperandTests {

    @Test("Every operand is named by the letter CLDR's rule text uses", arguments: [
        ("n", PluralOperand.absoluteValue),
        ("i", .integerPart),
        ("v", .fractionDigitCount),
        ("w", .significantFractionDigitCount),
        ("f", .fractionDigits),
        ("t", .significantFractionDigits),
    ])
    func lettersNameOperands(_ letter: String, _ operand: PluralOperand) {
        #expect(PluralOperand(rawValue: letter) == operand)
    }

    @Test("A letter CLDR does not use names no operand")
    func unknownLetterIsRejected() {
        #expect(PluralOperand(rawValue: "e") == nil)
    }

    @Test("A whole value keeps the remainder of dividing by a modulus")
    func wholeValueIsReduced() {
        #expect(PluralOperand.Value.whole(23).reduced(modulo: 10) == .whole(3))
    }

    @Test("A fractional value stays fractional through a modulus")
    func fractionalValueStaysFractional() {
        #expect(PluralOperand.Value.fractional.reduced(modulo: 10) == .fractional)
    }

    @Test("A whole value matches a range that covers it, and no other")
    func wholeValueMatchesItsRange() throws {
        let threeToFive = try #require(PluralRange(lowerBound: 3, upperBound: 5))
        let ranges = NonEmpty(PluralRange(0), [threeToFive])

        #expect(PluralOperand.Value.whole(0).matches(anyOf: ranges))
        #expect(PluralOperand.Value.whole(4).matches(anyOf: ranges))
        #expect(!PluralOperand.Value.whole(2).matches(anyOf: ranges))
    }

    @Test("A fractional value matches no range, because CLDR ranges hold whole numbers only")
    func fractionalValueMatchesNothing() throws {
        let wide = try #require(PluralRange(lowerBound: 0, upperBound: 100_000))

        #expect(!PluralOperand.Value.fractional.matches(anyOf: NonEmpty(wide)))
    }
}

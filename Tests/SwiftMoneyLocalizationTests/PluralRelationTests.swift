import SwiftMoneyLocalization
import Testing

@Suite("PluralRelation Tests")
struct PluralRelationTests {

    // CLDR's `i = 1`.
    static let integerPartIsOne = PluralRelation(
        operand: .integerPart,
        comparison: .equals(NonEmpty(PluralRange(1)))
    )

    @Test("An equals relation holds when the operand is in one of its ranges")
    func equalsHoldsInRange() {
        #expect(Self.integerPartIsOne.matches(PluralOperandValues(minorUnits: 1_00, unitScale: 100)))
        #expect(!Self.integerPartIsOne.matches(PluralOperandValues(minorUnits: 2_00, unitScale: 100)))
    }

    @Test("A not-equals relation holds when the operand is in none of its ranges")
    func notEqualsHoldsOutsideRanges() {
        let relation = PluralRelation(
            operand: .integerPart,
            comparison: .notEquals(NonEmpty(PluralRange(1)))
        )

        #expect(relation.matches(PluralOperandValues(minorUnits: 2_00, unitScale: 100)))
        #expect(!relation.matches(PluralOperandValues(minorUnits: 1_00, unitScale: 100)))
    }

    // CLDR's `i % 10 = 2..4`, from Polish's `few` rule.
    @Test("A modulus divides the operand before it is compared")
    func modulusAppliesBeforeComparison() throws {
        let twoToFour = try #require(PluralRange(lowerBound: 2, upperBound: 4))
        let relation = PluralRelation(
            operand: .integerPart,
            modulus: 10,
            comparison: .equals(NonEmpty(twoToFour))
        )

        #expect(relation.matches(PluralOperandValues(minorUnits: 12_00, unitScale: 100)))
        #expect(!relation.matches(PluralOperandValues(minorUnits: 15_00, unitScale: 100)))
    }

    // CLDR's `n = 1` is false for 1.50, and `n != 1` is therefore true.
    @Test("An amount with a fraction satisfies no equals relation on its absolute value")
    func fractionalAbsoluteValueNeverEquals() {
        let equals = PluralRelation(operand: .absoluteValue, comparison: .equals(NonEmpty(PluralRange(1))))
        let notEquals = PluralRelation(operand: .absoluteValue, comparison: .notEquals(NonEmpty(PluralRange(1))))
        let onePointFive = PluralOperandValues(minorUnits: 1_50, unitScale: 100)

        #expect(!equals.matches(onePointFive))
        #expect(notEquals.matches(onePointFive))
    }
}

import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

@Suite("PluralRule Tests")
struct PluralRuleTests {

    static func isOne(_ operand: PluralOperand) -> PluralRelation {
        PluralRelation(operand: operand, comparison: .equals(NonEmpty(PluralRange(1))))
    }

    static func isZero(_ operand: PluralOperand) -> PluralRelation {
        PluralRelation(operand: operand, comparison: .equals(NonEmpty(PluralRange(0))))
    }

    // English's and German's rule for `one`: `i = 1 and v = 0`.
    static let integerOneWithNoFractionDigits = PluralRule(
        orOfAndGroups: NonEmpty(NonEmpty(isOne(.integerPart), [isZero(.fractionDigitCount)]))
    )

    @Test("A rule holds when every relation in a group holds")
    func allRelationsInAGroupMustHold() {
        let oneYen = PluralOperandValues(minorUnits: 1, unitScale: 1)

        #expect(Self.integerOneWithNoFractionDigits.matches(oneYen))
    }

    @Test("A rule fails when one relation in its only group fails")
    func oneFailingRelationFailsTheGroup() {
        let twoYen = PluralOperandValues(minorUnits: 2, unitScale: 1)

        #expect(!Self.integerOneWithNoFractionDigits.matches(twoYen))
    }

    // The finding this phase is built around: a currency that shows fraction digits can never satisfy
    // `v = 0`, so one pound is plural by CLDR's rules however it is written.
    @Test(
        "A rule requiring no fraction digits cannot hold for a currency that shows them",
        arguments: [(minorUnits: 1_00 as Int64, scale: 100 as UnitScale), (minorUnits: 1_000, scale: 1_000)]
    )
    func fractionDigitsRuleOutTheOneCategory(_ row: (minorUnits: Int64, scale: UnitScale)) {
        let oneMajorUnit = PluralOperandValues(minorUnits: row.minorUnits, unitScale: row.scale)

        #expect(!Self.integerOneWithNoFractionDigits.matches(oneMajorUnit))
    }

    @Test("A rule holds when any one of its groups holds")
    func anyGroupCanSatisfyTheRule() {
        let rule = PluralRule(
            orOfAndGroups: NonEmpty(
                NonEmpty(Self.isZero(.integerPart)),
                [NonEmpty(Self.isOne(.integerPart))]
            )
        )

        #expect(rule.matches(PluralOperandValues(minorUnits: 1, unitScale: 1)))
        #expect(rule.matches(PluralOperandValues(minorUnits: 0, unitScale: 1)))
        #expect(!rule.matches(PluralOperandValues(minorUnits: 2, unitScale: 1)))
    }
}

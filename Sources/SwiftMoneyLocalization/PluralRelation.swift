/// One comparison in a plural rule, such as CLDR's `i % 10 = 2..4`.
package struct PluralRelation: Equatable, Sendable {
    private let operand: PluralOperand
    private let modulus: PluralModulus?
    private let comparison: Comparison

    /// Creates a relation between one operand of an amount and a list of ranges.
    ///
    /// - Parameter modulus: Divides the operand before it is compared, as CLDR's `%` does. `nil`
    ///   compares the operand itself.
    package init(operand: PluralOperand, modulus: PluralModulus? = nil, comparison: Comparison) {
        self.operand = operand
        self.modulus = modulus
        self.comparison = comparison
    }

    /// Returns whether an amount's operands satisfy this relation.
    package func matches(_ operands: PluralOperandValues) -> Bool {
        let value = reducedValue(in: operands)

        switch comparison {
        case .equals(let ranges):
            return value.matches(anyOf: ranges)
        case .notEquals(let ranges):
            return !value.matches(anyOf: ranges)
        }
    }

    private func reducedValue(in operands: PluralOperandValues) -> PluralOperand.Value {
        let value = operands.value(of: operand)

        guard let modulus else {
            return value
        }

        return value.reduced(modulo: modulus)
    }

    /// How a relation compares its operand against its ranges, named after CLDR's own operators.
    package enum Comparison: Equatable, Sendable {
        /// CLDR's `=`: the operand falls in one of the ranges.
        case equals(NonEmpty<PluralRange>)

        /// CLDR's `!=`: the operand falls in none of the ranges.
        case notEquals(NonEmpty<PluralRange>)
    }
}

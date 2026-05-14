// MARK: - Equatable

extension Rate: Equatable {
    /// Two rates are equal when their reduced fractions are identical.
    ///
    /// Because both fractions are stored in reduced (lowest-terms) form,
    /// equality is a simple field comparison — no cross-multiplication is
    /// required.
    ///
    /// ```swift
    /// Rate(numerator: 22, denominator: 200)
    ///     == Rate(numerator: 11, denominator: 100)  // true
    /// ```
    public static func == (lhs: Rate, rhs: Rate) -> Bool {
        lhs._numerator == rhs._numerator && lhs._denominator == rhs._denominator
    }
}

// MARK: - Hashable

extension Rate: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_numerator)
        hasher.combine(_denominator)
    }
}

// MARK: - Comparable

extension Rate: Comparable {
    /// Returns whether `lhs` represents a smaller rate than `rhs`.
    ///
    /// Uses cross-multiplication: `lhs < rhs` iff
    /// `lhs.numerator × rhs.denominator < rhs.numerator × lhs.denominator`.
    /// Both denominators are positive, so the inequality direction is preserved.
    ///
    /// - Precondition: The cross products must not overflow `Int64`.
    public static func < (lhs: Rate, rhs: Rate) -> Bool {
        let (lhsProduct, lhsOverflow) = lhs._numerator
            .multipliedReportingOverflow(by: rhs._denominator)
        let (rhsProduct, rhsOverflow) = rhs._numerator
            .multipliedReportingOverflow(by: lhs._denominator)
        precondition(!lhsOverflow && !rhsOverflow,
                     "Rate comparison overflowed Int64")
        return lhsProduct < rhsProduct
    }
}

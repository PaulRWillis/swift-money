public extension MoneyOf.Steps {
    /// A position in a set of steps.
    ///
    /// A `Steps` hands indices out, as `startIndex`, `endIndex` and its `index(...)` methods, and a
    /// fixed position in the source can be written as a literal:
    ///
    /// ```swift
    /// steps[0]    // the first step
    /// ```
    ///
    /// Its only public initializer is ``init(integerLiteral:)``, so a runtime `Int` holding a count
    /// of something else, such as minor units, becomes a position only if that call is written out.
    /// Indices order by position.
    struct Index: Comparable, Hashable, Sendable {
        // How many steps this position is from the first. Index arithmetic can move it below zero or
        // past the end, as it can for `Array`; the subscript checks it.
        @usableFromInline
        let offset: Int

        @inlinable
        init(offset: Int) {
            self.offset = offset
        }

        /// Returns whether the first position comes before the second.
        @inlinable
        public static func < (
            lhs: Self,
            rhs: Self
        ) -> Bool {
            lhs.offset < rhs.offset
        }
    }
}

extension MoneyOf.Steps.Index: ExpressibleByIntegerLiteral {
    /// Creates the position a number of steps from the first, written as an integer literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so a negative one is a
    /// mistake in the source rather than bad input: it traps.
    ///
    /// ```swift
    /// let fourth: GBP.Steps.Index = 3    // fine
    /// let none: GBP.Steps.Index = -1     // traps
    /// ```
    ///
    /// - Parameter value: How many steps the position is from the first.
    /// - Precondition: `value` is not negative.
    @inlinable
    public init(integerLiteral value: Int) {
        precondition(value >= 0, "A position in a set of steps must not be negative")

        self.init(offset: value)
    }
}

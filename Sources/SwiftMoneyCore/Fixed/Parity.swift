// Whether a whole number is even or odd: how half-to-even breaks a tie.
@usableFromInline
package enum Parity {
    case even
    case odd

    @inlinable
    init(of value: some BinaryInteger) {
        self = value.isMultiple(of: 2) ? .even : .odd
    }

    /// Creates the parity of a 128-bit value.
    ///
    /// ```swift
    /// Parity(of: UInt128Words(high: 2, low: 1))   // .odd
    /// ```
    ///
    /// - Parameter value: The value whose parity to take.
    package init(of value: UInt128Words) {
        self = value.parity
    }
}

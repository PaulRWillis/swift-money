extension Int128 {
    /// An exponent whose power of ten an `Int128` can hold: `0...38`.
    package struct DecimalExponent: Equatable, Hashable, Sendable {
        fileprivate let _storage: UInt8

        /// Creates an exponent, or `nil` unless `value` is `0...38`.
        package init?(exactly value: Int) {
            guard Int128.powersOfTen.indices.contains(value) else {
                return nil
            }

            // Truncating is exact here, `value` being a table index; the checked form measured 16
            // instructions on every `Rate` construction.
            _storage = UInt8(truncatingIfNeeded: value)
        }
    }

    // Ten raised to `exponent`.
    static func powerOfTen(_ exponent: DecimalExponent) -> Int128 {
        powersOfTen[Int(exponent._storage)]
    }

    // A literal, so it is initialized statically: a table built by a closure pays a lazy-init check on
    // every read.
    private static let powersOfTen: [Int128] = [
        1,
        10,
        100,
        1_000,
        10_000,
        100_000,
        1_000_000,
        10_000_000,
        100_000_000,
        1_000_000_000,
        10_000_000_000,
        100_000_000_000,
        1_000_000_000_000,
        10_000_000_000_000,
        100_000_000_000_000,
        1_000_000_000_000_000,
        10_000_000_000_000_000,
        100_000_000_000_000_000,
        1_000_000_000_000_000_000,
        10_000_000_000_000_000_000,
        100_000_000_000_000_000_000,
        1_000_000_000_000_000_000_000,
        10_000_000_000_000_000_000_000,
        100_000_000_000_000_000_000_000,
        1_000_000_000_000_000_000_000_000,
        10_000_000_000_000_000_000_000_000,
        100_000_000_000_000_000_000_000_000,
        1_000_000_000_000_000_000_000_000_000,
        10_000_000_000_000_000_000_000_000_000,
        100_000_000_000_000_000_000_000_000_000,
        1_000_000_000_000_000_000_000_000_000_000,
        10_000_000_000_000_000_000_000_000_000_000,
        100_000_000_000_000_000_000_000_000_000_000,
        1_000_000_000_000_000_000_000_000_000_000_000,
        10_000_000_000_000_000_000_000_000_000_000_000,
        100_000_000_000_000_000_000_000_000_000_000_000,
        1_000_000_000_000_000_000_000_000_000_000_000_000,
        10_000_000_000_000_000_000_000_000_000_000_000_000,
        100_000_000_000_000_000_000_000_000_000_000_000_000,
    ]
}

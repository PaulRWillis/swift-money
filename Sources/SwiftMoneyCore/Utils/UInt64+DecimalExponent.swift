extension UInt64 {
    /// An exponent whose power of ten a `UInt64` can hold: `0...19`.
    @usableFromInline
    package struct DecimalExponent: Equatable, Hashable, Sendable {
        @usableFromInline
        let _storage: UInt8

        // Every caller has proven `value` is `0...19`, so truncating is exact.
        @usableFromInline
        init(unchecked value: Int) {
            _storage = UInt8(truncatingIfNeeded: value)
        }

        /// Creates an exponent, or `nil` unless `value` is `0...19`.
        // Inlinable, with the table's range written out rather than read from it: an out-of-line call
        // cost the format engine eight instructions on every rounded precision.
        @inlinable
        package init?(exactly value: Int) {
            guard (0 ... 19).contains(value) else {
                return nil
            }

            self.init(unchecked: value)
        }

        /// The exponent of `scale`'s decimal places, `0...18`.
        @usableFromInline
        package init(_ scale: UnitScale) {
            self.init(unchecked: scale.decimalPlaces)
        }

        /// The exponent of `length`'s digits, `0...19`.
        @usableFromInline
        package init(_ length: FractionLength) {
            self.init(unchecked: length.rawValue)
        }

        /// The position of `value`'s leading digit, counting the units digit as `0`.
        ///
        /// ```swift
        /// UInt64.DecimalExponent(leadingDigitOf: 99)            // 1
        /// UInt64.DecimalExponent(leadingDigitOf: UInt64.max)    // 19
        /// ```
        @usableFromInline
        package init(leadingDigitOf value: UInt64) {
            var position = 0
            var remaining = value

            while remaining >= 10 {
                remaining /= 10
                position += 1
            }

            self.init(unchecked: position)
        }
    }

    // Ten raised to `exponent`.
    @usableFromInline
    static func powerOfTen(_ exponent: DecimalExponent) -> UInt64 {
        powersOfTen[Int(exponent._storage)]
    }

    // A literal, so it is initialized statically: a table built by a closure pays a lazy-init check on
    // every read.
    private static let powersOfTen: [UInt64] = [
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
    ]
}

extension Int {
    /// Creates an integer from a decimal exponent, `0...19`.
    @usableFromInline
    package init(_ exponent: UInt64.DecimalExponent) {
        self = Int(exponent._storage)
    }
}

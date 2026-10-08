import SwiftMoneyCore
import SwiftMoneyCoreTestSupport

extension Gen where Value == UInt128Words {
    /// A generator of 128-bit values, half drawn uniformly from the whole range and half with a random
    /// number of leading zero bits, so small values and values straddling the 64-bit word boundary come
    /// up as often as full-width ones.
    ///
    /// Built from two random words, without the type's own shifts, so a generated case never depends on
    /// the code it checks.
    static var anyWords: Gen<UInt128Words> {
        Gen { seed in
            let high = UInt64.random(in: .min ... .max, using: &seed)
            let low = UInt64.random(in: .min ... .max, using: &seed)
            guard Bool.random(using: &seed) else {
                return UInt128Words(high: high, low: low)
            }

            let leadingZeros = Int.random(in: 0 ... 127, using: &seed)
            guard leadingZeros < 64 else {
                return UInt128Words(high: 0, low: low >> (leadingZeros - 64))
            }

            return UInt128Words(high: high >> leadingZeros, low: low)
        }
    }

    /// Values at and around the edges of each 64-bit word.
    static var wordBoundaries: [UInt128Words] {
        [
            UInt128Words(high: 0, low: 0),
            UInt128Words(high: 0, low: 1),
            UInt128Words(high: 0, low: 2),
            UInt128Words(high: 0, low: .max - 1),
            UInt128Words(high: 0, low: .max),
            UInt128Words(high: 1, low: 0),
            UInt128Words(high: 1, low: 1),
            UInt128Words(high: .max, low: 0),
            UInt128Words(high: 0x7FFF_FFFF_FFFF_FFFF, low: .max),
            UInt128Words(high: 0x8000_0000_0000_0000, low: 0),
            UInt128Words(high: .max, low: .max - 1),
            UInt128Words(high: .max, low: .max),
        ]
    }
}

@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
extension UInt128Words {
    /// Creates the two words of a standard-library value.
    ///
    /// - Parameter value: The value to split into words.
    init(stdlib value: UInt128) {
        self.init(high: UInt64(truncatingIfNeeded: value >> 64), low: UInt64(truncatingIfNeeded: value))
    }
}

@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
extension UInt128 {
    /// Creates the standard-library value two words hold.
    ///
    /// - Parameter words: The words to join.
    init(words: UInt128Words) {
        self = UInt128(words.high) << 64 | UInt128(words.low)
    }
}

/// The ten glyphs a locale writes the digits `0` through `9` with, such as Arabic-Indic `٠١٢٣٤٥٦٧٨٩` or
/// Devanagari `०१२३४५६७८९`.
///
/// A numbering system's ten digits are ten consecutive Unicode scalars of a single UTF-8 width, so the
/// set is captured by its first scalar alone: digit `value` is `zero` plus `value`. Holding one scalar
/// keeps the type trivial, so a ``MoneyFormat`` that carries the default ASCII set pays nothing to store
/// or read it. A set that is not ten consecutive same-width scalars cannot be represented and is rejected.
@usableFromInline
package struct DigitGlyphs: Equatable, Hashable, Sendable {
    /// The scalar for digit `0`; digit `value` is `zero` offset by `value`.
    @usableFromInline
    let zero: Unicode.Scalar

    /// How many UTF-8 bytes each glyph takes, shared by all ten.
    @usableFromInline
    package let bytesPerDigit: Int

    /// Creates a digit set from ten glyphs given as one string, or `nil` unless they are exactly ten
    /// consecutive Unicode scalars that share a UTF-8 width.
    package init?(_ digits: String) {
        let scalars = Array(digits.unicodeScalars)
        guard scalars.count == 10 else {
            return nil
        }

        let zero = scalars[0]
        let consecutive = scalars.enumerated().allSatisfy { $0.element.value == zero.value &+ UInt32($0.offset) }
        guard consecutive, Self.utf8Width(of: zero) == Self.utf8Width(of: scalars[9]) else {
            return nil
        }

        self.zero = zero
        self.bytesPerDigit = Self.utf8Width(of: zero)
    }

    /// The glyph for digit `value`, which must be `0` through `9`.
    @inlinable
    package subscript(_ value: Int) -> Unicode.Scalar {
        // `zero` came from valid scalars and the range is contiguous, so every digit's scalar is valid.
        guard let scalar = Unicode.Scalar(zero.value &+ UInt32(value)) else {
            preconditionFailure("digit glyph is not a valid scalar")  // coverage:ignore
        }
        return scalar
    }

    // How many bytes the scalar takes in UTF-8, from the code-point ranges the encoding is defined over.
    // A range of consecutive scalars has one width where its ends share one, which the initializer checks.
    private static func utf8Width(of scalar: Unicode.Scalar) -> Int {
        switch scalar.value {
        case 0 ..< 0x80: 1
        case 0x80 ..< 0x800: 2
        case 0x800 ..< 0x1_0000: 3
        default: 4
        }
    }
}

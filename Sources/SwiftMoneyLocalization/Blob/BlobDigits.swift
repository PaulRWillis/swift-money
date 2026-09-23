/// The digits the packed tables write their integers with: six bits each, most significant first.
///
/// The tables live in a `StaticString` literal, and a Swift literal carries text rather than bytes: a
/// byte above `0x7F` written into one comes back as a multi-byte scalar, so an offset counted in bytes
/// would no longer land where it was written. Every integer is therefore written as printable ASCII,
/// which a literal reproduces byte for byte. The alphabet ascends in ASCII, so records sorted by a
/// numeric key are also sorted as text and a generated table can be read as it stands.
package enum BlobDigits {
    /// How many bits one digit carries.
    package static let bits = 6

    /// How many digits an integer of each width takes, rounded up from its bits.
    package static let u8 = 2
    package static let u16 = 3
    package static let u32 = 6
    package static let u64 = 11

    /// How many digits a blob offset takes: 24 bits, enough for a blob far larger than any this ships.
    package static let offset = 4

    /// How many digits a pooled string's byte length takes: 12 bits, well above the longest name.
    package static let length = 2

    /// How many digits a ``StringRef`` takes: an offset and a length.
    package static let stringRef = offset + length

    /// How many digits a currency code takes. The blob stores only three-letter ISO codes, so it keeps
    /// three of the eight symbols `compactValue` can hold.
    package static let currencyCode = 3

    /// How many six-bit symbols a ``CurrencyCode/compactValue`` holds: 48 bits, six per symbol.
    package static let compactValueSymbols = 8

    /// The wire form of a currency code: the top ``currencyCode`` symbols of its `compactValue`, or `nil`
    /// unless the code is exactly that many symbols.
    ///
    /// `compactValue` is left aligned in ``compactValueSymbols`` slots, so a three-symbol code leaves the
    /// lower slots zero and its symbols sit in the top of the value. A longer code fills a lower slot, so
    /// it has no wire form and is reported rather than truncated to a code it is not, which is what keeps
    /// a longer code from matching a stored three-letter one.
    package static func currencyCodeWire(_ compactValue: UInt64) -> UInt64? {
        let shift = bits * (compactValueSymbols - currencyCode)
        return compactValue & ((UInt64(1) << shift) - 1) == 0 ? compactValue >> shift : nil
    }

    /// The digit standing for a six-bit value: `-`, `.`, `0`–`9`, `A`–`Z`, then `a`–`z`.
    ///
    /// - Parameter value: A value below 64. A wider one wraps into the alphabet rather than failing,
    ///   which cannot happen: only the generator writes digits, and it writes each field to width.
    package static func digit(for value: UInt8) -> UInt8 {
        switch value & 0b11_1111 {
        case 0: UInt8(ascii: "-")
        case 1: UInt8(ascii: ".")
        case let value where value <= 11: UInt8(ascii: "0") + value - 2
        case let value where value <= 37: UInt8(ascii: "A") + value - 12
        case let value: UInt8(ascii: "a") + value - 38
        }
    }

    /// The six-bit value a digit stands for.
    ///
    /// - Parameter digit: A digit ``digit(for:)`` wrote. A byte that is not one reads as some value
    ///   rather than failing: the tables are generated, so a read landing outside a field is a fault in
    ///   the generator, which the golden digests catch, and not input to be validated here.
    package static func value(of digit: UInt8) -> UInt8 {
        switch digit {
        case UInt8(ascii: "-"): 0
        case UInt8(ascii: "."): 1
        case UInt8(ascii: "0") ... UInt8(ascii: "9"): digit - UInt8(ascii: "0") + 2
        case UInt8(ascii: "A") ... UInt8(ascii: "Z"): digit - UInt8(ascii: "A") + 12
        default: digit &- UInt8(ascii: "a") &+ 38
        }
    }
}

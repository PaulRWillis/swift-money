/// The code identifying a currency, such as `GBP`.
///
/// Three to eight characters, letters `A`–`Z` and digits `0`–`9` only. Lowercase input is accepted
/// and normalized, so `"gbp"` and `"GBP"` are the same currency.
///
/// The rule is deliberately wider than ISO 4217's three letters, so that currencies outside the
/// standard — `USDT`, `SAFEMOON`, or an in-app `GEMS` — are expressible. It is not wide enough for
/// every token symbol in circulation: some contain punctuation, emoji, or non-Latin scripts, and a
/// rule permitting those would validate nothing.
public struct CurrencyCode: Equatable, Hashable, Sendable {
    // The eight bytes of a code, uppercased, first character in the high byte and zero padded to the
    // right. Comparing two codes is then one integer compare rather than a call into String, which
    // is what makes a runtime amount's arithmetic cheap, and the high-byte-first order means codes
    // sort as they read.
    private let storage: UInt64

    /// Creates a currency code from a string that may not be valid.
    ///
    /// Use this for codes that come from outside the program — user input, a database, an API
    /// response.
    ///
    /// Lowercase input is normalized, so the code created is not always the string passed in.
    ///
    /// - Parameter string: The code, in any case.
    /// - Returns: `nil` unless `string` is three to eight characters of `A`–`Z`, `a`–`z` or `0`–`9`.
    public init?(string: String) {
        guard let packed = Self.packed(string) else {
            return nil
        }

        self.storage = packed
    }

    // Lets a parser take the code out of a longer string without building a `String` for it.
    init?(utf8 bytes: some Collection<UInt8>) {
        guard let packed = Self.packed(bytes) else {
            return nil
        }

        self.storage = packed
    }

    // Each byte is checked before it is uppercased, never after. `"ß".uppercased()` is `"SS"`, so
    // uppercasing a whole string first would let two non-ASCII characters satisfy both the character
    // rule and the length rule.
    private static func packed(_ string: String) -> UInt64? {
        packed(string.utf8)
    }

    private static func packed(_ bytes: some Collection<UInt8>) -> UInt64? {
        guard (3...8).contains(bytes.count) else {
            return nil
        }

        var packed: UInt64 = 0

        for byte in bytes {
            guard byte.isASCIIAlphanumeric else {
                return nil
            }

            packed = packed << 8 | UInt64(byte.uppercasedASCII)
        }

        return packed << (8 * (8 - bytes.count))
    }

    // The code as one word, first character in the high byte.
    var packedValue: UInt64 { storage }

    // The bytes of the code, written into a buffer the caller sizes with `utf8Count`. Lets a caller
    // assemble a longer string in one pass rather than building this one and concatenating it.
    func write(into buffer: UnsafeMutableBufferPointer<UInt8>, at offset: inout Int) {
        for shift in stride(from: 56, through: 0, by: -8) {
            let byte = UInt8(truncatingIfNeeded: storage >> shift)

            guard byte != 0 else {
                return
            }

            buffer[offset] = byte
            offset += 1
        }
    }

    // How many bytes `write(into:at:)` will write.
    var utf8Count: Int {
        var count = 0

        while count < 8, UInt8(truncatingIfNeeded: storage >> (56 - 8 * count)) != 0 {
            count += 1
        }

        return count
    }

    fileprivate var stringValue: String {
        String(unsafeUninitializedCapacity: 8) { buffer in
            var count = 0

            while count < 8 {
                let byte = UInt8(truncatingIfNeeded: storage >> (56 - 8 * count))

                guard byte != 0 else {
                    break
                }

                buffer[count] = byte
                count += 1
            }

            return count
        }
    }
}

// Deliberately byte-level rather than `Character.isLetter`/`.isNumber`, which are true for
// Arabic-Indic, Devanagari, fullwidth and other non-Latin digits. Here the permitted set is
// structural: `isASCIIDigit` cannot mean anything but `0`–`9`.
private extension UInt8 {
    var isASCIIUppercase: Bool {
        (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(self)
    }

    var isASCIILowercase: Bool {
        (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(self)
    }

    var isASCIIDigit: Bool {
        (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(self)
    }

    var isASCIIAlphanumeric: Bool {
        isASCIIUppercase || isASCIILowercase || isASCIIDigit
    }

    var uppercasedASCII: UInt8 {
        isASCIILowercase ? self - (UInt8(ascii: "a") - UInt8(ascii: "A")) : self
    }
}

extension CurrencyCode: ExpressibleByStringLiteral {
    /// Creates a currency code from a string literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so an invalid one is a
    /// mistake in the source rather than bad input — it traps instead of failing gracefully. Use
    /// ``init(string:)`` for any string that is not a literal.
    ///
    /// ```swift
    /// let gbp: CurrencyCode = "GBP"    // fine
    /// let oops: CurrencyCode = "£"     // traps
    /// ```
    ///
    /// - Parameter value: The code, in any case.
    /// - Precondition: `value` is three to eight characters of `A`–`Z`, `a`–`z` or `0`–`9`.
    public init(stringLiteral value: String) {
        guard let packed = Self.packed(value) else {
            preconditionFailure("Not a valid currency code: \(value)")
        }

        self.storage = packed
    }
}

extension CurrencyCode: CustomStringConvertible {
    public var description: String {
        stringValue
    }
}

public extension String {
    /// Creates a string from a currency code.
    init(_ code: CurrencyCode) {
        self = code.stringValue
    }
}

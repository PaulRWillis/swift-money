/// The code identifying a currency, such as `GBP`.
///
/// Three to eight characters, letters `A`–`Z` and digits `0`–`9` only. Lowercase input is accepted
/// and normalized, so `"gbp"` and `"GBP"` are the same currency.
///
/// The rule is deliberately wider than ISO 4217's three letters, so that currencies outside the
/// standard (`USDT`, `SAFEMOON`, or an in-app `GEMS`) are expressible. It is not wide enough for
/// every token symbol in circulation: some contain punctuation, emoji, or non-Latin scripts, and a
/// rule permitting those would validate nothing.
public struct CurrencyCode: Equatable, Hashable, Sendable {
    // Characters fill slots from the top and empty slots trail, so codes compare and sort as one integer.
    @usableFromInline
    let storage: UInt64

    private static let characterSlots = 8
    private static let bitsPerCharacter = 6
    private static let validLengths = 3...characterSlots
    private static let characterMask: UInt64 = (1 << bitsPerCharacter) - 1
    private static let emptySlot: UInt8 = 0
    fileprivate static let packedLetters =
        (emptySlot + 1)...(emptySlot + UInt8(ascii: "Z") - UInt8(ascii: "A") + 1)
    fileprivate static let packedDigits =
        (packedLetters.upperBound + 1)...(packedLetters.upperBound + UInt8(ascii: "9") - UInt8(ascii: "0") + 1)

    /// Creates a currency code from a string that may not be valid.
    ///
    /// Use this for codes that come from outside the program: user input, a database, an API
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

    // Checks each byte before uppercasing: `"ß".uppercased()` is `"SS"`, which would pass as two letters.
    private static func packed(_ string: String) -> UInt64? {
        let bytes = string.utf8

        guard validLengths.contains(bytes.count) else {
            return nil
        }

        var packed: UInt64 = 0

        for byte in bytes {
            guard byte.isASCIIAlphanumeric else {
                return nil
            }

            packed = appending(byte.uppercasedASCII.characterValue, to: packed)
        }

        return leftAligned(packed, count: bytes.count)
    }

    private static func appending(_ value: UInt8, to packed: UInt64) -> UInt64 {
        packed << bitsPerCharacter | UInt64(value)
    }

    @inline(__always)
    private static func leftAligned(_ packed: UInt64, count: Int) -> UInt64 {
        packed << (bitsPerCharacter * (characterSlots - count))
    }

    private static func value(inSlot slot: Int, of word: UInt64) -> UInt8 {
        UInt8(truncatingIfNeeded: word >> (bitsPerCharacter * (characterSlots - 1 - slot)) & characterMask)
    }

    // Trusts its input: the word must be a valid code's compact value.
    @inlinable
    init(unchecked packed: UInt64) {
        self.storage = packed
    }

    // The code a run of bytes starts with and the index after its space, or `nil` if it has none.
    static func leading(
        in utf8: UnsafeBufferPointer<UInt8>
    ) -> (code: CurrencyCode, after: Int)? {
        var packed: UInt64 = 0
        var count = 0

        for index in utf8.indices {
            let byte = utf8[index]

            if byte == UInt8(ascii: " ") {
                guard validLengths.contains(count) else {
                    return nil
                }

                return (CurrencyCode(unchecked: leftAligned(packed, count: count)), index + 1)
            }

            guard count < characterSlots, byte.isASCIIAlphanumeric else {
                return nil
            }

            packed = appending(byte.uppercasedASCII.characterValue, to: packed)
            count += 1
        }

        return nil
    }

    // The stored word: the form the byte serializer writes and the packed tables key on.
    @inlinable
    package var compactValue: UInt64 { storage }

    // Validating, unlike `init(unchecked:)`, because the word comes from outside.
    @usableFromInline
    package init?(compactValue: UInt64) {
        var packed: UInt64 = 0
        var count = 0

        for slot in 0..<Self.characterSlots {
            let value = Self.value(inSlot: slot, of: compactValue)

            guard value != Self.emptySlot else {
                break
            }
            guard UInt8(characterValue: value) != nil else {
                return nil
            }

            packed = Self.appending(value, to: packed)
            count += 1
        }

        guard Self.validLengths.contains(count) else {
            return nil
        }

        self.storage = Self.leftAligned(packed, count: count)
    }

    // Writes into a buffer the caller sized with `utf8Count`, so a longer string is built in one pass.
    func write(into buffer: UnsafeMutableBufferPointer<UInt8>, at offset: inout Int) {
        for slot in 0..<Self.characterSlots {
            let value = Self.value(inSlot: slot, of: storage)

            // Storage holds only validated codes, so every non-empty slot maps to a byte.
            guard value != Self.emptySlot, let byte = UInt8(characterValue: value) else {
                return
            }

            buffer[offset] = byte
            offset += 1
        }
    }

    // How many bytes `write(into:at:)` will write.
    var utf8Count: Int {
        var count = 0

        while count < Self.characterSlots, Self.value(inSlot: count, of: storage) != Self.emptySlot {
            count += 1
        }

        return count
    }

    fileprivate var stringValue: String {
        String(unsafeUninitializedCapacity: Self.characterSlots) { buffer in
            var count = 0

            while count < Self.characterSlots {
                let value = Self.value(inSlot: count, of: storage)

                guard value != Self.emptySlot, let byte = UInt8(characterValue: value) else {
                    break
                }

                buffer[count] = byte
                count += 1
            }

            return count
        }
    }
}

// Byte-level on purpose: `Character.isNumber` accepts non-ASCII digits such as Arabic-Indic.
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

    // Called only on bytes already known alphanumeric.
    var characterValue: UInt8 {
        isASCIIDigit
            ? self - UInt8(ascii: "0") + CurrencyCode.packedDigits.lowerBound
            : self - UInt8(ascii: "A") + CurrencyCode.packedLetters.lowerBound
    }

    // The inverse of `characterValue`, validating because the value comes from outside.
    init?(characterValue value: UInt8) {
        switch value {
        case CurrencyCode.packedLetters:
            self = UInt8(ascii: "A") + value - CurrencyCode.packedLetters.lowerBound
        case CurrencyCode.packedDigits:
            self = UInt8(ascii: "0") + value - CurrencyCode.packedDigits.lowerBound
        default:
            return nil
        }
    }
}

extension CurrencyCode: ExpressibleByStringLiteral {
    /// Creates a currency code from a string literal.
    ///
    /// A literal is written by a programmer rather than derived from data, so an invalid one is a
    /// mistake in the source rather than bad input, so it traps instead of failing gracefully. Use
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

#if !hasFeature(Embedded)

extension CurrencyCode: Codable {
    /// Writes the code as a string, in upper case.
    ///
    /// ```swift
    /// let code: CurrencyCode = "gbp"
    ///
    /// try encoder.encode(code)   // "GBP"
    /// ```
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(stringValue)
    }

    /// Reads a code from a string.
    ///
    /// Use this for a type of your own that carries a code. An amount that carries its own currency
    /// needs nothing here, and ``MoneyCodingFormat/fields`` reads a currency field beside an amount.
    ///
    /// ```swift
    /// struct ExchangeRate: Decodable {
    ///     let from: CurrencyCode
    ///     let to: CurrencyCode
    ///     let rate: String
    /// }
    /// ```
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the string is not a valid code.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)

        guard let code = CurrencyCode(string: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: """
                    Not a valid currency code: "\(string)". \
                    A code is three to eight characters of A-Z, a-z or 0-9.
                    """
            )
        }

        self = code
    }
}

#endif

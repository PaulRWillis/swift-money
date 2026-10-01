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

    /// How many characters the stored word holds: 8.
    @inlinable
    static var characterSlots: Int { 8 }

    /// How many bits each character takes: 6.
    @inlinable
    static var bitsPerCharacter: Int { 6 }

    /// How many characters an ISO 4217 code has: 3.
    @inlinable
    static var isoCodeLength: Int { 3 }

    /// The fewest characters a code may have.
    private static let minLength = 3

    /// The most characters a code may have.
    private static let maxLength = 8

    /// How many characters a code may have: 3 to 8.
    private static let acceptedLengths = minLength...maxLength

    /// The six bits of the lowest slot.
    private static let characterMask: UInt64 = 0b11_1111

    /// The packed value of a slot with no character in it.
    private static let emptySlot: UInt8 = 0

    /// The packed values of `A` to `Z`, in order. These are the library's own, not ASCII.
    fileprivate static let packedLetters: ClosedRange<UInt8> = 1...26

    /// The packed values of `0` to `9`, in order.
    fileprivate static let packedDigits: ClosedRange<UInt8> = 27...36

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

        guard acceptedLengths.contains(bytes.count) else {
            return nil
        }

        var packed: UInt64 = 0

        for byte in bytes {
            guard byte.isASCIIAlphanumeric else {
                return nil
            }

            packed = appending(byte.uppercasedASCII.packedCharacter, to: packed)
        }

        return leftAligned(packed, count: bytes.count)
    }

    private static func appending(_ character: UInt8, to packed: UInt64) -> UInt64 {
        packed << bitsPerCharacter | UInt64(character)
    }

    // Forced inline: an outlined copy can't see the count is 3 to 8, so it keeps overflow traps.
    @inline(__always)
    private static func leftAligned(_ packed: UInt64, count: Int) -> UInt64 {
        packed << (bitsPerCharacter * (characterSlots - count))
    }

    /// Returns the packed character in a slot of a word.
    ///
    /// - Parameters:
    ///   - slot: The slot, counting from 0 at the top.
    ///   - word: The packed word.
    /// - Returns: The slot's packed character, ``emptySlot`` when it holds none.
    private static func packedCharacter(inSlot slot: Int, of word: UInt64) -> UInt8 {
        let slotsBelow = characterSlots - 1 - slot

        return UInt8(truncatingIfNeeded: word >> (slotsBelow * bitsPerCharacter) & characterMask)
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
                guard acceptedLengths.contains(count) else {
                    return nil
                }

                return (CurrencyCode(unchecked: leftAligned(packed, count: count)), index + 1)
            }

            guard count < maxLength, byte.isASCIIAlphanumeric else {
                return nil
            }

            packed = appending(byte.uppercasedASCII.packedCharacter, to: packed)
            count += 1
        }

        return nil
    }

    // The stored word: the form the byte serializer writes and the packed tables key on.
    @inlinable
    package var compactValue: UInt64 { storage }

    /// The code packed into three character slots, or `nil` unless it is three characters long.
    @inlinable
    package var threeCharacterValue: UInt64? {
        let bitsAfterCode = Self.bitsPerCharacter * (Self.characterSlots - Self.isoCodeLength)

        return storage.trailingZeroBitCount >= bitsAfterCode ? storage >> bitsAfterCode : nil
    }

    /// Creates a code from its packed word, or `nil` unless the word is exactly a code's own.
    ///
    /// A code's word holds three to eight characters left-aligned, with every slot after the last
    /// character empty and no bit set above the eight slots.
    ///
    /// ```swift
    /// CurrencyCode(compactValue: 0x1C24_0000_0000)  // GBP
    /// CurrencyCode(compactValue: 0x1C24_0000_0001)  // nil, a character after an empty slot
    /// ```
    ///
    /// - Parameter compactValue: A packed word, such as one read back from bytes.
    /// - Returns: `nil` unless `compactValue` is the ``compactValue`` of some code.
    @usableFromInline
    package init?(compactValue: UInt64) {
        var packed: UInt64 = 0
        var count = 0

        for slot in 0..<Self.characterSlots {
            let character = Self.packedCharacter(inSlot: slot, of: compactValue)

            guard character != Self.emptySlot else {
                break
            }
            guard UInt8(packedCharacter: character) != nil else {
                return nil
            }

            packed = Self.appending(character, to: packed)
            count += 1
        }

        // The loop stops at the first empty slot, so this refuses any bit it did not read.
        guard Self.acceptedLengths.contains(count),
              Self.leftAligned(packed, count: count) == compactValue else {
            return nil
        }

        self.storage = compactValue
    }

    // Writes into a buffer the caller sized with `utf8Count`, so a longer string is built in one pass.
    func write(into buffer: UnsafeMutableBufferPointer<UInt8>, at offset: inout Int) {
        for slot in 0..<Self.characterSlots {
            let character = Self.packedCharacter(inSlot: slot, of: storage)

            // Storage holds only validated codes, so every non-empty slot maps to a byte.
            guard character != Self.emptySlot, let byte = UInt8(packedCharacter: character) else {
                return
            }

            buffer[offset] = byte
            offset += 1
        }
    }

    // How many bytes `write(into:at:)` will write.
    var utf8Count: Int {
        var count = 0

        while count < Self.characterSlots,
              Self.packedCharacter(inSlot: count, of: storage) != Self.emptySlot {
            count += 1
        }

        return count
    }

    fileprivate var stringValue: String {
        String(unsafeUninitializedCapacity: Self.characterSlots) { buffer in
            var count = 0

            while count < Self.characterSlots {
                let character = Self.packedCharacter(inSlot: count, of: storage)

                guard character != Self.emptySlot,
                      let byte = UInt8(packedCharacter: character) else {
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
    var packedCharacter: UInt8 {
        isASCIIDigit
            ? self - UInt8(ascii: "0") + CurrencyCode.packedDigits.lowerBound
            : self - UInt8(ascii: "A") + CurrencyCode.packedLetters.lowerBound
    }

    // The inverse of `packedCharacter`, or `nil` for a value outside both ranges.
    init?(packedCharacter character: UInt8) {
        switch character {
        case CurrencyCode.packedLetters:
            self = UInt8(ascii: "A") + character - CurrencyCode.packedLetters.lowerBound
        case CurrencyCode.packedDigits:
            self = UInt8(ascii: "0") + character - CurrencyCode.packedDigits.lowerBound
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

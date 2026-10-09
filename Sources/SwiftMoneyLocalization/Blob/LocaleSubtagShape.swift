/// The kind of locale identifier subtag a run of bytes can be, judged by its length and characters.
///
/// ```swift
/// LocaleSubtagShape("Latn".utf8)   // .script
/// LocaleSubtagShape("gb".utf8)     // .region
/// LocaleSubtagShape("POSIX".utf8)  // nil
/// ```
package enum LocaleSubtagShape: Sendable, Equatable {
    /// Four ASCII letters, such as `Latn`.
    case script

    /// Two ASCII letters or three ASCII digits, such as `GB` or `419`.
    case region

    /// Creates the shape of a subtag, or returns `nil` when it is neither a script's nor a region's.
    ///
    /// Letters match in either case.
    ///
    /// ```swift
    /// LocaleSubtagShape("latn".utf8)  // .script
    /// LocaleSubtagShape("419".utf8)   // .region
    /// LocaleSubtagShape("G1".utf8)    // nil
    /// ```
    ///
    /// - Parameter subtag: The subtag's UTF-8 bytes, without separators.
    /// - Returns: `nil` when `subtag` is neither four ASCII letters, two ASCII letters nor three ASCII
    ///   digits.
    /// - Complexity: O(*n*), where *n* is the length of `subtag`.
    package init?(_ subtag: some Collection<UInt8>) {
        let tally = subtag.reduce(into: Tally()) { $0.count($1) }

        guard let shape = tally.shape else {
            return nil
        }

        self = shape
    }
}

extension LocaleSubtagShape {
    /// What a subtag's bytes are so far, read one byte at a time: how many, and whether all are
    /// letters or all digits.
    struct Tally {
        /// How many bytes have been read.
        private(set) var length = 0

        /// Whether every byte read is an ASCII letter.
        private var allLetters = true

        /// Whether every byte read is an ASCII digit.
        private var allDigits = true

        /// Counts one more byte of the subtag.
        ///
        /// - Parameter byte: The subtag's next byte.
        mutating func count(_ byte: UInt8) {
            length += 1
            allLetters = allLetters && Self.isLetter(byte)
            allDigits = allDigits && Self.isDigit(byte)
        }

        /// The shape of the bytes read, or `nil` when they are neither a script's nor a region's.
        var shape: LocaleSubtagShape? {
            switch length {
            case Self.scriptLength where allLetters: .script
            case Self.letterRegionLength where allLetters: .region
            case Self.numericRegionLength where allDigits: .region
            default: nil
            }
        }

        /// The length of a script subtag, such as `Latn`.
        private static let scriptLength = 4

        /// The length of a letter region subtag, such as `GB`.
        private static let letterRegionLength = 2

        /// The length of a numeric region subtag, such as `419`.
        private static let numericRegionLength = 3

        /// The bit that tells an ASCII capital letter from its small letter.
        private static let asciiCaseBit: UInt8 = 0x20

        /// Returns whether a byte is an ASCII letter, in either case.
        ///
        /// - Parameter byte: The byte to check.
        /// - Returns: `true` if `byte` is `A` to `Z` or `a` to `z`; otherwise, `false`.
        private static func isLetter(_ byte: UInt8) -> Bool {
            (UInt8(ascii: "a") ... UInt8(ascii: "z")).contains(byte | asciiCaseBit)
        }

        /// Returns whether a byte is an ASCII digit.
        ///
        /// - Parameter byte: The byte to check.
        /// - Returns: `true` if `byte` is `0` to `9`; otherwise, `false`.
        private static func isDigit(_ byte: UInt8) -> Bool {
            (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(byte)
        }
    }
}

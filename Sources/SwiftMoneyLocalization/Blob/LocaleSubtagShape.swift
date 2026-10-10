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
        let tally = subtag.reduce(into: Tally.empty) { $0.count($1) }

        guard let shape = tally.shape else {
            return nil
        }

        self = shape
    }
}

extension LocaleSubtagShape {
    /// What a subtag's bytes read so far could still be, one byte at a time.
    enum Tally {
        /// No bytes.
        case empty

        /// One ASCII letter.
        case oneLetter

        /// Two ASCII letters, a letter region's length.
        case twoLetters

        /// Three ASCII letters.
        case threeLetters

        /// Four ASCII letters, a script's length.
        case fourLetters

        /// One ASCII digit.
        case oneDigit

        /// Two ASCII digits.
        case twoDigits

        /// Three ASCII digits, a numeric region's length.
        case threeDigits

        /// Bytes no script or region starts with: a byte that is neither an ASCII letter nor an ASCII
        /// digit, a mix of the two, or more of either than any shape has.
        case shapeless

        /// Counts one more byte of the subtag.
        ///
        /// - Parameter byte: The subtag's next byte.
        mutating func count(_ byte: UInt8) {
            self = if Self.isLetter(byte) {
                afterLetter
            } else if Self.isDigit(byte) {
                afterDigit
            } else {
                .shapeless
            }
        }

        /// The shape of the bytes read, or `nil` when they are neither a script's nor a region's.
        var shape: LocaleSubtagShape? {
            switch self {
            case .fourLetters: .script
            case .twoLetters, .threeDigits: .region
            case .empty, .oneLetter, .threeLetters, .oneDigit, .twoDigits, .shapeless: nil
            }
        }

        /// The tally after one more ASCII letter.
        private var afterLetter: Tally {
            switch self {
            case .empty: .oneLetter
            case .oneLetter: .twoLetters
            case .twoLetters: .threeLetters
            case .threeLetters: .fourLetters
            case .fourLetters, .oneDigit, .twoDigits, .threeDigits, .shapeless: .shapeless
            }
        }

        /// The tally after one more ASCII digit.
        private var afterDigit: Tally {
            switch self {
            case .empty: .oneDigit
            case .oneDigit: .twoDigits
            case .twoDigits: .threeDigits
            case .oneLetter, .twoLetters, .threeLetters, .fourLetters, .threeDigits, .shapeless: .shapeless
            }
        }

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

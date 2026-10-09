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

        /// ASCII letters only, no more than a script has, with how many.
        case letters(count: Int)

        /// ASCII digits only, no more than a numeric region has, with how many.
        case digits(count: Int)

        /// Bytes no script or region starts with: a byte that is neither an ASCII letter nor an ASCII
        /// digit, a mix of the two, or more of either than any shape has.
        case shapeless

        /// Counts one more byte of the subtag.
        ///
        /// - Parameter byte: The subtag's next byte.
        mutating func count(_ byte: UInt8) {
            self = switch self {
            case .empty where Self.isLetter(byte): .letters(count: 1)
            case .empty where Self.isDigit(byte): .digits(count: 1)
            case .letters(let count) where count < Self.scriptLength && Self.isLetter(byte):
                .letters(count: count + 1)
            case .digits(let count) where count < Self.numericRegionLength && Self.isDigit(byte):
                .digits(count: count + 1)
            case .empty, .letters, .digits, .shapeless: .shapeless
            }
        }

        /// The shape of the bytes read, or `nil` when they are neither a script's nor a region's.
        var shape: LocaleSubtagShape? {
            switch self {
            case .letters(count: Self.scriptLength): .script
            case .letters(count: Self.letterRegionLength), .digits(count: Self.numericRegionLength): .region
            case .empty, .letters, .digits, .shapeless: nil
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

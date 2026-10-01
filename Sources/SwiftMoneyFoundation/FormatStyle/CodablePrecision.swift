import Foundation

// A format style's precision, written as Foundation's `Precision` writes it and read back here instead.
// Foundation's decoder refuses the `null` its own encoder writes for a bound left unset, so a fraction
// length, or any range open at one end, never reads back (verified on Swift 6.3.2). Writing still goes
// through Foundation, the only way into an opaque `Precision`, which keeps the JSON as it always was.
// Reading rebuilds the value through Foundation's public factories, so it refuses what they cannot take.
struct CodablePrecision: Codable {
    typealias Precision = NumberFormatStyleConfiguration.Precision

    private typealias Option = KeyedDecodingContainer<OptionKeys>

    private enum CodingKeys: String, CodingKey {
        case option
    }

    private enum OptionKeys: String, CodingKey {
        case minSignificantDigits
        case maxSignificantDigits
        case minIntegerLength
        case maxIntegerLength
        case minFractionalLength
        case maxFractionalLength
    }

    /// The family of keys a precision's option names.
    private enum KeyFamily {
        /// The fewest and most significant digits.
        case significantDigits

        /// The fewest and most integer and fraction digits.
        case lengths

        /// Creates the family of keys the given option names.
        ///
        /// A key counts as named when it is present, even with a `null` value.
        ///
        /// - Parameter option: A precision's option.
        /// - Throws: `DecodingError.dataCorrupted` if `option` names keys from both families, or
        ///   from neither.
        init(in option: Option) throws {
            let namesSignificantDigits = CodablePrecision.significantDigitKeys.contains(where: option.contains)
            let namesLengths = CodablePrecision.lengthKeys.contains(where: option.contains)

            switch (namesSignificantDigits, namesLengths) {
            case (true, true):
                throw CodablePrecision.corrupted(option, "A precision names both significant digits and lengths.")
            case (true, false):
                self = .significantDigits
            case (false, true):
                self = .lengths
            case (false, false):
                throw CodablePrecision.corrupted(option, "A precision names no limit on its digits.")
            }
        }
    }

    /// The fewest and most digits one part of a precision allows.
    private enum LengthLimits {
        /// Exactly the given number of digits.
        case exactly(Int)

        /// A number of digits within the given range, whose bounds differ.
        case within(ClosedRange<Int>)

        /// At least the given number of digits.
        case atLeast(Int)

        /// At most the given number of digits.
        case atMost(Int)
    }

    /// The fewest and most significant digits a precision allows.
    ///
    /// A significant-digits precision always names its fewest digits, so there is no at-most case.
    private enum SignificantDigitLimits {
        /// Exactly the given number of digits.
        case exactly(Int)

        /// A number of digits within the given range, whose bounds differ.
        case within(ClosedRange<Int>)

        /// At least the given number of digits.
        case atLeast(Int)
    }

    /// A precision as its JSON states it, before Foundation's factories build it.
    private enum ParsedPrecision: Decodable {
        /// Limits on the significant digits.
        case significantDigits(SignificantDigitLimits)

        /// Limits on the integer digits alone.
        case integerLength(LengthLimits)

        /// Limits on the fraction digits alone.
        case fractionLength(LengthLimits)

        /// Limits on both the integer and the fraction digits.
        case integerAndFractionLength(integer: LengthLimits, fraction: LengthLimits)

        /// The precision Foundation's factories build from these limits.
        ///
        /// A part fixed at one length goes through a single-length factory, which keeps any length.
        var precision: Precision {
            switch self {
            case let .significantDigits(.exactly(digits)):
                .significantDigits(digits)
            case let .significantDigits(.within(digits)):
                .significantDigits(digits)
            case let .significantDigits(.atLeast(digits)):
                .significantDigits(digits...)
            case let .integerLength(.exactly(length)):
                .integerLength(length)
            case let .integerLength(.within(lengths)):
                .integerLength(lengths)
            case let .integerLength(.atLeast(length)):
                .integerLength(length...)
            case let .integerLength(.atMost(length)):
                .integerLength(...length)
            case let .fractionLength(.exactly(length)):
                .fractionLength(length)
            case let .fractionLength(.within(lengths)):
                .fractionLength(lengths)
            case let .fractionLength(.atLeast(length)):
                .fractionLength(length...)
            case let .fractionLength(.atMost(length)):
                .fractionLength(...length)
            case let .integerAndFractionLength(.exactly(integer), .exactly(fraction)):
                .integerAndFractionLength(integer: integer, fraction: fraction)
            case let .integerAndFractionLength(integer, fraction):
                Self.precision(integer: integer, fraction: fraction)
            }
        }

        /// Creates a precision's limits by decoding them from the given decoder.
        ///
        /// - Parameter decoder: The decoder to read from.
        /// - Throws: `DecodingError` if the option is missing, names both families of keys or
        ///   neither, holds a bound that isn't a whole number, holds a length below zero or a
        ///   significant-digit count below one, puts a part's fewest digits above its most, or
        ///   names a significant-digit limit without its fewest digits.
        init(from decoder: any Decoder) throws {
            let option = try decoder.container(keyedBy: CodingKeys.self)
                .nestedContainer(keyedBy: OptionKeys.self, forKey: .option)

            switch try KeyFamily(in: option) {
            case .significantDigits:
                self = .significantDigits(try Self.significantDigitLimits(in: option))
            case .lengths:
                self = try Self.lengths(in: option)
            }
        }

        /// Returns the limits on a precision's integer and fraction digits.
        ///
        /// - Parameter option: A precision's option that names lengths.
        /// - Returns: The limits on whichever parts `option` names.
        /// - Throws: `DecodingError` if `option` holds an invalid bound, or names no bound at all.
        private static func lengths(in option: Option) throws -> Self {
            let integer = try lengthLimits(.minIntegerLength, .maxIntegerLength, in: option)
            let fraction = try lengthLimits(.minFractionalLength, .maxFractionalLength, in: option)

            switch (integer, fraction) {
            case (nil, nil):
                throw CodablePrecision.corrupted(option, "A precision names no limit on its digits.")
            case let (integer?, nil):
                return .integerLength(integer)
            case let (nil, fraction?):
                return .fractionLength(fraction)
            case let (integer?, fraction?):
                return .integerAndFractionLength(integer: integer, fraction: fraction)
            }
        }

        /// Returns the limits on one part's length, or `nil` if the option names neither bound.
        ///
        /// - Parameters:
        ///   - fewestKey: The key of the part's fewest digits.
        ///   - mostKey: The key of the part's most digits.
        ///   - option: A precision's option.
        /// - Returns: The part's limits, or `nil` if neither key holds a value.
        /// - Throws: `DecodingError` if a bound isn't a whole number, is below zero, or the fewest
        ///   digits are above the most.
        private static func lengthLimits(
            _ fewestKey: OptionKeys,
            _ mostKey: OptionKeys,
            in option: Option
        ) throws -> LengthLimits? {
            let fewest = try count(fewestKey, allowed: CodablePrecision.validLengths, in: option)
            let most = try count(mostKey, allowed: CodablePrecision.validLengths, in: option)

            switch (fewest, most) {
            case (nil, nil):
                return nil
            case let (fewest?, nil):
                return .atLeast(fewest)
            case let (nil, most?):
                return .atMost(most)
            case let (fewest?, most?):
                guard fewest != most else { return .exactly(fewest) }
                return .within(try range(fewest, most, fewestKey: fewestKey, in: option))
            }
        }

        /// Returns the limits on a precision's significant digits.
        ///
        /// - Parameter option: A precision's option that names significant digits.
        /// - Returns: The significant-digit limits.
        /// - Throws: `DecodingError` if a bound isn't a whole number, is below one, the fewest
        ///   digits are missing, or the fewest are above the most.
        private static func significantDigitLimits(in option: Option) throws -> SignificantDigitLimits {
            let allowed = CodablePrecision.validSignificantDigits
            let fewest = try count(.minSignificantDigits, allowed: allowed, in: option)
            let most = try count(.maxSignificantDigits, allowed: allowed, in: option)

            switch (fewest, most) {
            case (nil, _):
                throw DecodingError.dataCorruptedError(
                    forKey: .minSignificantDigits,
                    in: option,
                    debugDescription: "A significant-digits precision must name its fewest digits."
                )
            case let (fewest?, nil):
                return .atLeast(fewest)
            case let (fewest?, most?):
                guard fewest != most else { return .exactly(fewest) }
                return .within(try range(fewest, most, fewestKey: .minSignificantDigits, in: option))
            }
        }

        /// Returns the digit count at the given key, or `nil` if the key is absent or `null`.
        ///
        /// - Parameters:
        ///   - key: The key to read.
        ///   - allowed: The counts a precision accepts.
        ///   - option: A precision's option.
        /// - Returns: The count, or `nil` if `key` holds no value.
        /// - Throws: `DecodingError.typeMismatch` if the value isn't a whole number;
        ///   `DecodingError.dataCorrupted` if it's outside `allowed`.
        private static func count(
            _ key: OptionKeys,
            allowed: PartialRangeFrom<Int>,
            in option: Option
        ) throws -> Int? {
            guard let count = try option.decodeIfPresent(Int.self, forKey: key) else { return nil }
            guard allowed.contains(count) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: option,
                    debugDescription: "Not a valid digit count: \(count). The fewest allowed is \(allowed.lowerBound)."
                )
            }
            return count
        }

        /// Returns the range between two different bounds.
        ///
        /// - Parameters:
        ///   - fewest: The fewest digits.
        ///   - most: The most digits, which must differ from `fewest`.
        ///   - fewestKey: The key of `fewest`, which an error names.
        ///   - option: A precision's option.
        /// - Returns: `fewest...most`.
        /// - Throws: `DecodingError.dataCorrupted` if `fewest` is above `most`.
        private static func range(
            _ fewest: Int,
            _ most: Int,
            fewestKey: OptionKeys,
            in option: Option
        ) throws -> ClosedRange<Int> {
            guard fewest < most else {
                throw DecodingError.dataCorruptedError(
                    forKey: fewestKey,
                    in: option,
                    debugDescription: "A precision's lower bound \(fewest) is above its upper bound \(most)."
                )
            }
            return fewest...most
        }

        /// Returns a mixed precision whose parts are not both fixed at one length.
        ///
        /// - Parameters:
        ///   - integer: The integer digits' limits.
        ///   - fraction: The fraction digits' limits.
        /// - Returns: The precision Foundation's range factory builds from both parts.
        private static func precision(integer: LengthLimits, fraction: LengthLimits) -> Precision {
            switch integer {
            case let .exactly(length):
                precision(integer: length...length, fraction: fraction)
            case let .within(lengths):
                precision(integer: lengths, fraction: fraction)
            case let .atLeast(length):
                precision(integer: length..., fraction: fraction)
            case let .atMost(length):
                precision(integer: ...length, fraction: fraction)
            }
        }

        /// Returns a mixed precision from the integer digits' range and the fraction's limits.
        ///
        /// - Parameters:
        ///   - integer: The integer digits' range.
        ///   - fraction: The fraction digits' limits.
        /// - Returns: The precision Foundation's range factory builds from both parts.
        private static func precision(integer: some RangeExpression<Int>, fraction: LengthLimits) -> Precision {
            switch fraction {
            case let .exactly(length):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: length...length)
            case let .within(lengths):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: lengths)
            case let .atLeast(length):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: length...)
            case let .atMost(length):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: ...length)
            }
        }
    }

    private static let significantDigitKeys: [OptionKeys] = [.minSignificantDigits, .maxSignificantDigits]
    private static let lengthKeys: [OptionKeys] = [
        .minIntegerLength, .maxIntegerLength, .minFractionalLength, .maxFractionalLength,
    ]
    private static let validLengths: PartialRangeFrom<Int> = 0...
    private static let validSignificantDigits: PartialRangeFrom<Int> = 1...

    let precision: Precision

    init(_ precision: Precision) {
        self.precision = precision
    }

    init(from decoder: any Decoder) throws {
        precision = try ParsedPrecision(from: decoder).precision
    }

    func encode(to encoder: any Encoder) throws {
        try precision.encode(to: encoder)
    }

    private static func corrupted(_ option: Option, _ description: String) -> DecodingError {
        .dataCorrupted(DecodingError.Context(codingPath: option.codingPath, debugDescription: description))
    }
}

import Foundation

/// A format style's precision, written in the shape Foundation's `Precision` writes.
///
/// Reads back the fraction lengths and one-sided ranges Foundation's own decoder refuses, and
/// refuses a bound Foundation's factories would clamp rather than change it.
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
        ///   significant-digit count below one, puts a part's fewest digits above its most, names
        ///   a significant-digit limit without its fewest digits, or holds a bound Foundation's
        ///   range factories would clamp.
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
                if case .exactly = integer, case .exactly = fraction {
                    return .integerAndFractionLength(integer: integer, fraction: fraction)
                }
                return .integerAndFractionLength(
                    integer: try rangePart(integer, key: .maxIntegerLength, in: option),
                    fraction: try rangePart(fraction, key: .maxFractionalLength, in: option)
                )
            }
        }

        /// Returns one part of a mixed precision whose parts aren't both fixed at one length.
        ///
        /// Foundation builds such a precision through its range factory, which clamps a part fixed
        /// at one length as it clamps a closed range.
        ///
        /// - Parameters:
        ///   - part: The part's limits.
        ///   - key: The key an error names.
        ///   - option: A precision's option.
        /// - Returns: `part`, unchanged.
        /// - Throws: `DecodingError.dataCorrupted` if `part` is fixed at more digits than
        ///   ``closedRangeCeiling``.
        private static func rangePart(
            _ part: LengthLimits,
            key: OptionKeys,
            in option: Option
        ) throws -> LengthLimits {
            if case let .exactly(length) = part, length > CodablePrecision.closedRangeCeiling {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: option,
                    debugDescription: """
                        A length of \(length) beside a range is above the most Foundation keeps, \
                        \(CodablePrecision.closedRangeCeiling).
                        """
                )
            }
            return part
        }

        /// Returns the limits on one part's length, or `nil` if the option names neither bound.
        ///
        /// - Parameters:
        ///   - fewestKey: The key of the part's fewest digits.
        ///   - mostKey: The key of the part's most digits.
        ///   - option: A precision's option.
        /// - Returns: The part's limits, or `nil` if neither key holds a value.
        /// - Throws: `DecodingError` if a bound isn't a whole number, is below zero, the fewest
        ///   digits are above the most, or a bound is one Foundation's range factories would clamp.
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
                return .atLeast(try oneSidedBound(fewest, key: fewestKey, in: option))
            case let (nil, most?):
                return .atMost(try oneSidedBound(most, key: mostKey, in: option))
            case let (fewest?, most?):
                guard fewest != most else { return .exactly(fewest) }
                return .within(try range(fewest, most, keys: (fewestKey, mostKey), in: option))
            }
        }

        /// Returns the limits on a precision's significant digits.
        ///
        /// - Parameter option: A precision's option that names significant digits.
        /// - Returns: The significant-digit limits.
        /// - Throws: `DecodingError` if a bound isn't a whole number, is below one, the fewest
        ///   digits are missing, the fewest are above the most, or a bound is one Foundation's
        ///   range factories would clamp.
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
                return .atLeast(try oneSidedBound(fewest, key: .minSignificantDigits, in: option))
            case let (fewest?, most?):
                guard fewest != most else { return .exactly(fewest) }
                let keys = (fewest: OptionKeys.minSignificantDigits, most: OptionKeys.maxSignificantDigits)
                return .within(try range(fewest, most, keys: keys, in: option))
            }
        }

        /// Returns the bound of a range open at one end.
        ///
        /// - Parameters:
        ///   - bound: The bound.
        ///   - key: The key of `bound`, which an error names.
        ///   - option: A precision's option.
        /// - Returns: `bound`, unchanged.
        /// - Throws: `DecodingError.dataCorrupted` if `bound` is above ``oneSidedCeiling``.
        private static func oneSidedBound(_ bound: Int, key: OptionKeys, in option: Option) throws -> Int {
            guard bound <= CodablePrecision.oneSidedCeiling else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: option,
                    debugDescription: """
                        A one-sided bound of \(bound) is above the most Foundation keeps, \
                        \(CodablePrecision.oneSidedCeiling).
                        """
                )
            }
            return bound
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
        ///   - keys: The keys of `fewest` and `most`, which an error names.
        ///   - option: A precision's option.
        /// - Returns: `fewest...most`.
        /// - Throws: `DecodingError.dataCorrupted` if `fewest` is above `most`, or `most` is above
        ///   ``closedRangeCeiling``.
        private static func range(
            _ fewest: Int,
            _ most: Int,
            keys: (fewest: OptionKeys, most: OptionKeys),
            in option: Option
        ) throws -> ClosedRange<Int> {
            guard fewest < most else {
                throw DecodingError.dataCorruptedError(
                    forKey: keys.fewest,
                    in: option,
                    debugDescription: "A precision's lower bound \(fewest) is above its upper bound \(most)."
                )
            }
            guard most <= CodablePrecision.closedRangeCeiling else {
                throw DecodingError.dataCorruptedError(
                    forKey: keys.most,
                    in: option,
                    debugDescription: """
                        A range's upper bound \(most) is above the most Foundation keeps, \
                        \(CodablePrecision.closedRangeCeiling).
                        """
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

    /// The most digits Foundation's range factories keep in a closed range's bound: 998.
    ///
    /// Measured on Swift 6.4. It also limits a mixed precision's part fixed at one length, which
    /// goes through the same factories.
    private static let closedRangeCeiling = 998

    /// The most digits Foundation's range factories keep in a range open at one end: 999.
    ///
    /// Measured on Swift 6.4.
    private static let oneSidedCeiling = 999

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

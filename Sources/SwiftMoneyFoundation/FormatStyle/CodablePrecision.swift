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

    /// A closed range of digit counts whose bounds differ, which Foundation's range factories keep.
    private struct DigitRange {
        /// The range, whose upper bound is above its lower and at most ``closedRangeCeiling``.
        let counts: ClosedRange<Int>

        /// Creates a range from its bounds.
        ///
        /// - Parameters:
        ///   - fewest: The fewest digits.
        ///   - most: The most digits.
        ///   - keys: The keys of `fewest` and `most`, which an error names.
        ///   - option: A precision's option.
        /// - Throws: `DecodingError.dataCorrupted` if `fewest` isn't below `most`, or `most` is
        ///   above ``closedRangeCeiling``.
        init(fewest: Int, most: Int, keys: (fewest: OptionKeys, most: OptionKeys), in option: Option) throws {
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
            counts = fewest...most
        }
    }

    /// The bound of a range of digit counts open at one end, which Foundation's range factories keep.
    private struct OneSidedBound {
        /// The bound, at most ``oneSidedCeiling``.
        let count: Int

        /// Creates a one-sided bound.
        ///
        /// - Parameters:
        ///   - count: The bound.
        ///   - key: The key of `count`, which an error names.
        ///   - option: A precision's option.
        /// - Throws: `DecodingError.dataCorrupted` if `count` is above ``oneSidedCeiling``.
        init(_ count: Int, key: OptionKeys, in option: Option) throws {
            guard count <= CodablePrecision.oneSidedCeiling else {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: option,
                    debugDescription: """
                        A one-sided bound of \(count) is above the most Foundation keeps, \
                        \(CodablePrecision.oneSidedCeiling).
                        """
                )
            }
            self.count = count
        }
    }

    /// The fewest and most digits one part of a precision allows.
    private enum LengthLimits {
        /// Exactly the given number of digits.
        case exactly(Int)

        /// A number of digits within the given range.
        case within(DigitRange)

        /// At least the given number of digits.
        case atLeast(OneSidedBound)

        /// At most the given number of digits.
        case atMost(OneSidedBound)
    }

    /// One part of a precision whose integer and fraction parts aren't both fixed at one length.
    ///
    /// Foundation builds such a precision through its range factory, which clamps a part fixed at
    /// one length as it clamps a closed range.
    private struct RangedPart {
        /// The part's limits, fixed at no more than ``closedRangeCeiling`` digits when exact.
        let limits: LengthLimits

        /// Creates a part from its limits.
        ///
        /// - Parameters:
        ///   - limits: The part's limits.
        ///   - key: The key an error names.
        ///   - option: A precision's option.
        /// - Throws: `DecodingError.dataCorrupted` if `limits` is fixed at more digits than
        ///   ``closedRangeCeiling``.
        init(_ limits: LengthLimits, key: OptionKeys, in option: Option) throws {
            if case let .exactly(length) = limits, length > CodablePrecision.closedRangeCeiling {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: option,
                    debugDescription: """
                        A length of \(length) beside a range is above the most Foundation keeps, \
                        \(CodablePrecision.closedRangeCeiling).
                        """
                )
            }
            self.limits = limits
        }

        /// The precision Foundation's range factory builds from this part as the integer digits.
        ///
        /// - Parameter fraction: The fraction digits.
        /// - Returns: The mixed precision.
        func precision(fraction: RangedPart) -> Precision {
            switch limits {
            case let .exactly(length):
                fraction.precision(integer: length...length)
            case let .within(lengths):
                fraction.precision(integer: lengths.counts)
            case let .atLeast(length):
                fraction.precision(integer: length.count...)
            case let .atMost(length):
                fraction.precision(integer: ...length.count)
            }
        }

        /// The precision Foundation's range factory builds from this part as the fraction digits.
        ///
        /// - Parameter integer: The integer digits' range.
        /// - Returns: The mixed precision.
        private func precision(integer: some RangeExpression<Int>) -> Precision {
            switch limits {
            case let .exactly(length):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: length...length)
            case let .within(lengths):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: lengths.counts)
            case let .atLeast(length):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: length.count...)
            case let .atMost(length):
                .integerAndFractionLength(integerLimits: integer, fractionLimits: ...length.count)
            }
        }
    }

    /// The fewest and most significant digits a precision allows.
    ///
    /// Foundation writes an at-most limit with a fewest of one digit.
    private enum SignificantDigitLimits {
        /// Exactly the given number of digits.
        case exactly(Int)

        /// A number of digits within the given range, whose lower bound is above one.
        case within(DigitRange)

        /// At least the given number of digits.
        case atLeast(OneSidedBound)

        /// At most the given number of digits, which is above one.
        case atMost(OneSidedBound)
    }

    /// A precision as its JSON states it, inside the limits Foundation's factories keep.
    private enum ParsedPrecision: Decodable {
        /// Limits on the significant digits.
        case significantDigits(SignificantDigitLimits)

        /// Limits on the integer digits alone.
        case integerLength(LengthLimits)

        /// Limits on the fraction digits alone.
        case fractionLength(LengthLimits)

        /// An exact number of integer digits and an exact number of fraction digits.
        case fixedLengths(integer: Int, fraction: Int)

        /// Limits on both the integer and the fraction digits, not both fixed at one length.
        case rangedLengths(integer: RangedPart, fraction: RangedPart)

        /// The precision Foundation's factories build from these limits.
        ///
        /// An exact limit goes through a single-length factory, which keeps any length.
        var precision: Precision {
            switch self {
            case let .significantDigits(.exactly(digits)):
                .significantDigits(digits)
            case let .significantDigits(.within(digits)):
                .significantDigits(digits.counts)
            case let .significantDigits(.atLeast(digits)):
                .significantDigits(digits.count...)
            case let .significantDigits(.atMost(digits)):
                .significantDigits(...digits.count)
            case let .integerLength(.exactly(length)):
                .integerLength(length)
            case let .integerLength(.within(lengths)):
                .integerLength(lengths.counts)
            case let .integerLength(.atLeast(length)):
                .integerLength(length.count...)
            case let .integerLength(.atMost(length)):
                .integerLength(...length.count)
            case let .fractionLength(.exactly(length)):
                .fractionLength(length)
            case let .fractionLength(.within(lengths)):
                .fractionLength(lengths.counts)
            case let .fractionLength(.atLeast(length)):
                .fractionLength(length.count...)
            case let .fractionLength(.atMost(length)):
                .fractionLength(...length.count)
            case let .fixedLengths(integer, fraction):
                .integerAndFractionLength(integer: integer, fraction: fraction)
            case let .rangedLengths(integer, fraction):
                integer.precision(fraction: fraction)
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
            case let (.exactly(integer)?, .exactly(fraction)?):
                return .fixedLengths(integer: integer, fraction: fraction)
            case let (integer?, fraction?):
                return .rangedLengths(
                    integer: try RangedPart(integer, key: .maxIntegerLength, in: option),
                    fraction: try RangedPart(fraction, key: .maxFractionalLength, in: option)
                )
            }
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
                return .atLeast(try OneSidedBound(fewest, key: fewestKey, in: option))
            case let (nil, most?):
                return .atMost(try OneSidedBound(most, key: mostKey, in: option))
            case let (fewest?, most?):
                guard fewest != most else { return .exactly(fewest) }
                return .within(try DigitRange(fewest: fewest, most: most, keys: (fewestKey, mostKey), in: option))
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
                return .atLeast(try OneSidedBound(fewest, key: .minSignificantDigits, in: option))
            case let (fewest?, most?):
                guard fewest != most else { return .exactly(fewest) }
                // Foundation writes `...most` with a fewest of one, and keeps an at-most bound past
                // the most a closed range keeps, so this has to read as one-sided.
                if fewest == allowed.lowerBound {
                    return .atMost(try OneSidedBound(most, key: .maxSignificantDigits, in: option))
                }
                let keys = (fewest: OptionKeys.minSignificantDigits, most: OptionKeys.maxSignificantDigits)
                return .within(try DigitRange(fewest: fewest, most: most, keys: keys, in: option))
            }
        }

        /// Returns the digit count at the given key, or `nil` if the key is absent or `null`.
        ///
        /// - Parameters:
        ///   - key: The key to read.
        ///   - allowed: The counts a precision accepts.
        ///   - option: A precision's option.
        /// - Returns: The count, or `nil` if `key` holds no value.
        /// - Throws: `DecodingError.typeMismatch` if the value isn't a number; the decoder's error
        ///   for a number that isn't whole, which from `JSONDecoder` is `DecodingError.dataCorrupted`
        ///   with an empty coding path; `DecodingError.dataCorrupted` if the count is outside
        ///   `allowed`.
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
    }

    private static let significantDigitKeys: [OptionKeys] = [.minSignificantDigits, .maxSignificantDigits]
    private static let lengthKeys: [OptionKeys] = [
        .minIntegerLength, .maxIntegerLength, .minFractionalLength, .maxFractionalLength,
    ]
    private static let validLengths: PartialRangeFrom<Int> = 0...
    private static let validSignificantDigits: PartialRangeFrom<Int> = 1...

    /// The most digits Foundation's range factories keep in a closed range's upper bound: 998.
    ///
    /// Foundation clamps a length range to its `validPartLength`, `0..<999`, and a significant-digits
    /// range to its `validSignificantDigits`, `1..<999`. A closed range clamped to a half-open one
    /// ends at 998. The same holds for a mixed precision's part fixed at one length, which goes
    /// through the range factory. Measured on Swift 6.4.
    private static let closedRangeCeiling = 998

    /// The most digits Foundation's range factories keep in a range open at one end: 999.
    ///
    /// Foundation clamps a one-sided bound, of lengths or of significant digits, to the end of the
    /// same half-open ranges, so it keeps 999. Measured on Swift 6.4.
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

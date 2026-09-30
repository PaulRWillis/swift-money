import Foundation

// A format style's precision, written as Foundation's `Precision` writes it and read back here instead.
// Foundation's decoder refuses the `null` its own encoder writes for a bound left unset, so a fraction
// length, or any range open at one end, never reads back (verified on Swift 6.3.2). Writing still goes
// through Foundation, the only way into an opaque `Precision`, which keeps the JSON as it always was.
// Reading rebuilds the value through Foundation's public factories, so it refuses what they cannot take.
struct CodablePrecision: Codable {
    typealias Precision = NumberFormatStyleConfiguration.Precision

    private typealias Option = KeyedDecodingContainer<OptionKeys>
    private typealias Bounds = (lower: Int?, upper: Int?)

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
        let option = try decoder.container(keyedBy: CodingKeys.self)
            .nestedContainer(keyedBy: OptionKeys.self, forKey: .option)
        let namesSignificantDigits = Self.significantDigitKeys.contains(where: option.contains)
        let namesLengths = Self.lengthKeys.contains(where: option.contains)

        switch (namesSignificantDigits, namesLengths) {
        case (true, true):
            throw Self.corrupted(option, "A precision names both significant digits and lengths.")
        case (true, false):
            precision = try Self.significantDigits(in: option)
        case (false, _):
            precision = try Self.lengths(in: option)
        }
    }

    func encode(to encoder: any Encoder) throws {
        try precision.encode(to: encoder)
    }

    private static func significantDigits(in option: Option) throws -> Precision {
        let digits = try bounds(
            .minSignificantDigits, .maxSignificantDigits, allowed: validSignificantDigits, in: option
        )

        guard digits.lower != nil, let limits = range(digits) else {
            throw DecodingError.dataCorruptedError(
                forKey: .minSignificantDigits,
                in: option,
                debugDescription: "A significant-digits precision must name its fewest digits."
            )
        }

        return exactly(digits).map { .significantDigits($0) } ?? .significantDigits(limits)
    }

    // A part fixed at one length goes through the single-length factory: the range factories clamp to
    // Foundation's limits and the single-length ones do not, so only they rebuild every length it wrote.
    private static func lengths(in option: Option) throws -> Precision {
        let integer = try bounds(.minIntegerLength, .maxIntegerLength, allowed: validLengths, in: option)
        let fraction = try bounds(.minFractionalLength, .maxFractionalLength, allowed: validLengths, in: option)

        switch (range(integer), range(fraction)) {
        case (nil, nil):
            throw corrupted(option, "A precision names no limit on its digits.")
        case let (integerLimits?, nil):
            return exactly(integer).map { .integerLength($0) } ?? .integerLength(integerLimits)
        case let (nil, fractionLimits?):
            return exactly(fraction).map { .fractionLength($0) } ?? .fractionLength(fractionLimits)
        case let (integerLimits?, fractionLimits?):
            if let integer = exactly(integer), let fraction = exactly(fraction) {
                return .integerAndFractionLength(integer: integer, fraction: fraction)
            }
            return .integerAndFractionLength(integerLimits: integerLimits, fractionLimits: fractionLimits)
        }
    }

    // One part's bounds, each within `allowed` and the lower no greater than the upper, which is what
    // lets `range(_:)` build a closed range from them without trapping.
    private static func bounds(
        _ lowerKey: OptionKeys,
        _ upperKey: OptionKeys,
        allowed: PartialRangeFrom<Int>,
        in option: Option
    ) throws -> Bounds {
        let lower = try option.decodeIfPresent(Int.self, forKey: lowerKey)
        let upper = try option.decodeIfPresent(Int.self, forKey: upperKey)

        for (key, count) in [(lowerKey, lower), (upperKey, upper)] {
            if let count, !allowed.contains(count) {
                throw DecodingError.dataCorruptedError(
                    forKey: key,
                    in: option,
                    debugDescription: "Not a valid digit count: \(count). The fewest allowed is \(allowed.lowerBound)."
                )
            }
        }

        if let lower, let upper, lower > upper {
            throw DecodingError.dataCorruptedError(
                forKey: lowerKey,
                in: option,
                debugDescription: "A precision's lower bound \(lower) is above its upper bound \(upper)."
            )
        }

        return (lower, upper)
    }

    private static func range(_ bounds: Bounds) -> (any RangeExpression<Int>)? {
        switch bounds {
        case let (lower?, upper?):
            lower...upper
        case let (lower?, nil):
            lower...
        case let (nil, upper?):
            ...upper
        case (nil, nil):
            nil
        }
    }

    private static func exactly(_ bounds: Bounds) -> Int? {
        bounds.lower == bounds.upper ? bounds.lower : nil
    }

    private static func corrupted(_ option: Option, _ description: String) -> DecodingError {
        .dataCorrupted(DecodingError.Context(codingPath: option.codingPath, debugDescription: description))
    }
}

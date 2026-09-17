// A Foundation-free currency formatter. Given a `MoneyFormat` descriptor holding the locale-dependent
// pieces (separators, grouping, symbol, placement) and a set of display options mirroring
// `Decimal.FormatStyle.Currency`'s modifiers, it renders a `MoneyOf` to a localized string without ICU.
//
// The descriptor is presentation-resolved by its source (a locale-data provider such as
// `SwiftMoneyLocalization`, or a caller with a fixed format): `.standard`/`.isoCode`/`.narrow` differ
// only in the symbol string the descriptor carries, so the engine itself is presentation-agnostic.

/// The locale-dependent pieces a currency amount is rendered with, held as plain data so the amount can
/// be formatted without consulting ICU at render time.
public struct MoneyFormat: Equatable, Hashable, Sendable {
    /// Whether the currency symbol precedes the digits or follows them.
    public enum SymbolPlacement: Equatable, Hashable, Sendable {
        case before
        case after
    }

    /// A locale's rule for splitting the whole digits into groups, like the thousands separators in
    /// `1,234,567`.
    ///
    /// Most locales repeat a single group size; build those with ``repeating(_:separator:)``. A few,
    /// such as India, use a smaller size above the first group, giving `12,34,567` for the same number.
    public enum GroupingScheme: Equatable, Hashable, Sendable {
        /// The digits are not grouped: `1234567`.
        case none

        /// Separate the least significant `primary` digits, then every `secondary` digits above them,
        /// with `separator` between the groups.
        ///
        /// ```swift
        /// .digits(primary: 3, secondary: 2, separator: ",")   // 12,34,567  (India)
        /// ```
        case digits(primary: GroupingSize, secondary: GroupingSize, separator: GroupingSeparator)
    }

    /// The currency symbol as the chosen presentation renders it: `"£"`, `"GBP"`, a narrow symbol, etc.
    public var symbol: String
    /// Where the symbol sits relative to the digits.
    public var placement: SymbolPlacement
    /// What separates the symbol from the digits, e.g. `""` or a non-breaking space.
    public var spacing: String
    /// What separates the whole part from the fraction, e.g. `"."` or `","`.
    public var decimalSeparator: String
    /// How the whole digits are grouped.
    public var grouping: GroupingScheme
    /// What marks a negative amount under the automatic/always sign strategies. Defaults to `"-"`.
    public var minusSign: String
    /// What marks a non-negative amount under the always sign strategy. Defaults to `"+"`.
    public var plusSign: String

    public init(
        symbol: String,
        placement: SymbolPlacement,
        spacing: String = "",
        decimalSeparator: String = ".",
        grouping: GroupingScheme = .repeating(3, separator: ","),
        minusSign: String = "-",
        plusSign: String = "+"
    ) {
        self.symbol = symbol
        self.placement = placement
        self.spacing = spacing
        self.decimalSeparator = decimalSeparator
        self.grouping = grouping
        self.minusSign = minusSign
        self.plusSign = plusSign
    }
}

public extension MoneyFormat.GroupingScheme {
    /// A grouping that repeats one `size` for every group, which is how most locales group.
    ///
    /// ```swift
    /// .repeating(3, separator: ",")   // 1,234,567
    /// ```
    static func repeating(_ size: GroupingSize, separator: GroupingSeparator) -> Self {
        .digits(primary: size, secondary: size, separator: separator)
    }
}

/// The display options that mirror `Decimal.FormatStyle.Currency`'s modifiers, minus the currency code
/// (which the amount carries). Defaults render the exact amount, grouped, with a sign only when negative.
public struct MoneyFormatOptions: Equatable, Hashable, Sendable {
    /// When a sign is written.
    public enum Sign: Equatable, Hashable, Sendable {
        /// A minus for a negative amount, nothing otherwise. The default.
        case automatic
        /// No sign, whatever the amount.
        case never
        /// A plus for a non-negative amount, a minus for a negative one.
        case always
        /// A negative amount in parentheses, a non-negative one plain.
        case accounting
    }

    /// When the decimal separator is written.
    public enum DecimalSeparator: Equatable, Hashable, Sendable {
        /// Written only when fraction digits follow it. The default.
        case automatic
        /// Always written, even for a whole amount.
        case always
    }

    /// Whether the whole digits are grouped, mirroring `Decimal.FormatStyle.Currency`'s grouping.
    public enum Grouping: Equatable, Hashable, Sendable {
        /// Group the whole digits using the format's grouping scheme. The default.
        case automatic
        /// Never group, whatever the format's scheme.
        case never
    }

    /// How many fraction digits are shown.
    public enum Precision: Equatable, Hashable, Sendable {
        /// The currency's own scale, so nothing rounds. The default.
        case currencyScale
        /// A fixed number of fraction digits. Fewer than the currency's scale rounds the shown value by
        /// `rounding`; more pads with zeros.
        case fixed(FractionLength, rounding: RoundingRule)
    }

    public var sign: Sign
    public var grouping: Grouping
    public var decimalSeparator: DecimalSeparator
    public var precision: Precision

    public init(
        sign: Sign = .automatic,
        grouping: Grouping = .automatic,
        decimalSeparator: DecimalSeparator = .automatic,
        precision: Precision = .currencyScale
    ) {
        self.sign = sign
        self.grouping = grouping
        self.decimalSeparator = decimalSeparator
        self.precision = precision
    }
}

public extension MoneyFormat {
    /// The amount, rendered with this format and the default options (exact digits, grouped, minus only
    /// when negative).
    @inlinable
    func format<C: CurrencyRepresentation>(_ money: MoneyOf<C>) -> String {
        format(money, options: MoneyFormatOptions())
    }

    /// The amount, rendered with this format and the given display options.
    @inlinable
    func format<C: CurrencyRepresentation>(_ money: MoneyOf<C>, options: MoneyFormatOptions) -> String {
        let places = money.currency.unitScale.decimalPlaces
        let digitsShown: Int
        let rounding: RoundingRule
        switch options.precision {
        case .currencyScale:
            // Shows every digit the currency divides into, so nothing is dropped and rounding is moot.
            (digitsShown, rounding) = (places, .toNearestOrEven)
        case .fixed(let length, let rule):
            (digitsShown, rounding) = (length.rawValue, rule)
        }
        let value = MoneyFormat.displayValue(
            money.minorUnits, scalePlaces: places, showing: digitsShown, rounding: rounding
        )

        let negative = value < 0
        let magnitude = value.magnitude
        let unit = UInt64.powerOfTen(digitsShown)
        let whole = digitsShown == 0 ? magnitude : magnitude / unit
        let fraction = digitsShown == 0 ? 0 : magnitude % unit

        let wholeDigits = MoneyFormat.digitCount(whole)
        // The grouping to apply, or `nil` to write the whole part ungrouped: the format has no grouping
        // scheme, the caller turned grouping off, or the number is too short to reach a group boundary.
        let groups: (primary: Int, secondary: Int, separator: String)?
        switch (grouping, options.grouping) {
        case (.digits(let p, let s, let sep), .automatic) where wholeDigits > p.rawValue:
            groups = (p.rawValue, s.rawValue, sep.rawValue)
        default:
            groups = nil
        }
        let separators = groups.map { 1 + (wholeDigits - $0.primary - 1) / $0.secondary } ?? 0
        let showsSeparator = digitsShown > 0 || options.decimalSeparator == .always

        let (leading, trailing) = affixes(negative: negative, sign: options.sign)

        let length =
            leading.utf8.count + trailing.utf8.count
            + symbol.utf8.count + spacing.utf8.count
            + wholeDigits
            + separators * (groups?.separator.utf8.count ?? 0)
            + (showsSeparator ? decimalSeparator.utf8.count : 0)
            + digitsShown

        return String(unsafeUninitializedCapacity: length) { buffer in
            var offset = 0

            offset = MoneyFormat.copy(leading, into: buffer, at: offset)
            if placement == .before {
                offset = MoneyFormat.copy(symbol, into: buffer, at: offset)
                offset = MoneyFormat.copy(spacing, into: buffer, at: offset)
            }

            offset = writeGroupedWhole(whole, digits: wholeDigits, groups: groups, into: buffer, at: offset)

            if showsSeparator {
                offset = MoneyFormat.copy(decimalSeparator, into: buffer, at: offset)
            }
            if digitsShown > 0 {
                offset = MoneyFormat.writeDigits(fraction, count: digitsShown, into: buffer, at: offset)
            }

            if placement == .after {
                offset = MoneyFormat.copy(spacing, into: buffer, at: offset)
                offset = MoneyFormat.copy(symbol, into: buffer, at: offset)
            }

            offset = MoneyFormat.copy(trailing, into: buffer, at: offset)
            return offset
        }
    }

    // What goes before and after the symbol-and-digits body under each sign strategy: a sign character
    // before, or accounting parentheses around.
    @inlinable
    func affixes(negative: Bool, sign: MoneyFormatOptions.Sign) -> (leading: String, trailing: String) {
        switch sign {
        case .automatic:
            (negative ? minusSign : "", "")
        case .never:
            ("", "")
        case .always:
            (negative ? minusSign : plusSign, "")
        case .accounting:
            negative ? ("(", ")") : ("", "")
        }
    }

    // The whole part, most significant digit first. With `groups`, inserts the separator before a digit
    // whenever the digits from it rightward complete a group: a separator precedes MSB-digit `i` when
    // `(digits - i - primary)` is a non-negative multiple of `secondary`, giving both the uniform
    // `1,234,567` and Indian `12,34,567` shapes. Without `groups`, the digits are written plain. Returns
    // the offset just past the whole part.
    @inlinable
    func writeGroupedWhole(
        _ whole: UInt64,
        digits: Int,
        groups: (primary: Int, secondary: Int, separator: String)?,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var next = offset
        var divisor = UInt64.powerOfTen(digits - 1)
        var remaining = whole

        for index in 0 ..< digits {
            if index > 0, let groups {
                let rightOf = digits - index - groups.primary
                if rightOf >= 0, rightOf % groups.secondary == 0 {
                    next = MoneyFormat.copy(groups.separator, into: buffer, at: next)
                }
            }

            buffer[next] = UInt8(remaining / divisor) &+ UInt8(ascii: "0")
            next += 1
            remaining %= divisor
            divisor /= 10
        }

        return next
    }

    // Copies a string's UTF8 bytes into the buffer, returning the offset just past them.
    @inlinable
    static func copy(
        _ string: String,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var next = offset
        for byte in string.utf8 {
            buffer[next] = byte
            next += 1
        }
        return next
    }

    // The fraction, zero padded to `count` digits, most significant first. Returns the offset just past.
    @inlinable
    static func writeDigits(
        _ value: UInt64,
        count: Int,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var next = offset
        var divisor = UInt64.powerOfTen(count - 1)
        var remaining = value

        while divisor > 0 {
            buffer[next] = UInt8(remaining / divisor) &+ UInt8(ascii: "0")
            next += 1
            remaining %= divisor
            divisor /= 10
        }

        return next
    }

    @inlinable
    static func digitCount(_ value: UInt64) -> Int {
        var digits = 1
        var remaining = value

        while remaining >= 10 {
            remaining /= 10
            digits += 1
        }

        return digits
    }

    // The minor-unit count re-expressed at `showing` fraction digits: unchanged when that equals the
    // currency's scale, padded (× a power of ten) when it is more, and rounded by `rounding` when it is
    // fewer. The result counts `10 ^ showing` per major unit.
    @inlinable
    static func displayValue(
        _ minorUnits: Int64,
        scalePlaces: Int,
        showing: Int,
        rounding: RoundingRule
    ) -> Int64 {
        if showing == scalePlaces {
            return minorUnits
        }
        if showing > scalePlaces {
            return minorUnits * Int64(UInt64.powerOfTen(showing - scalePlaces))
        }
        return roundedQuotient(minorUnits, by: Int64(UInt64.powerOfTen(scalePlaces - showing)), rule: rounding)
    }

    // `value / divisor`, rounded to a whole quotient by `rule`. Self-contained (no wide-int helpers) so
    // it stays inlinable. `divisor` is a positive power of ten.
    @inlinable
    static func roundedQuotient(_ value: Int64, by divisor: Int64, rule: RoundingRule) -> Int64 {
        let quotient = value / divisor
        let remainder = value % divisor
        guard remainder != 0 else {
            return quotient
        }

        let magnitude = remainder.magnitude
        let toNextWhole = divisor.magnitude - magnitude
        let negative = value < 0

        let awayFromZero: Bool
        switch rule {
        case .towardZero:
            awayFromZero = false
        case .awayFromZero:
            awayFromZero = true
        case .down:
            awayFromZero = negative
        case .up:
            awayFromZero = !negative
        case .toNearestOrAwayFromZero:
            awayFromZero = magnitude >= toNextWhole
        case .toNearestOrEven:
            awayFromZero = magnitude > toNextWhole
                || (magnitude == toNextWhole && !quotient.isMultiple(of: 2))
        @unknown default:
            awayFromZero = magnitude >= toNextWhole  // coverage:ignore — only a future RoundingRule case
        }

        guard awayFromZero else {
            return quotient
        }
        return quotient + (negative ? -1 : 1)
    }
}

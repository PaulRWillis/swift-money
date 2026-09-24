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
    /// A locale's rule for splitting the whole digits into groups, like the thousands separators in
    /// `1,234,567`.
    ///
    /// Most locales repeat a single group size; build those with ``repeating(_:separator:)``. A few,
    /// such as India, use a smaller size above the first group, giving `12,34,567` for the same number.
    @usableFromInline
    package enum GroupingScheme: Equatable, Hashable, Sendable {
        /// The digits are not grouped: `1234567`.
        case none

        /// Separate the least significant `primary` digits, then every `secondary` digits above them,
        /// with `separator` between the groups, once the whole part reaches `minGroupingDigits` digits
        /// beyond the first group.
        ///
        /// ```swift
        /// .digits(primary: 3, secondary: 2, separator: ",", minGroupingDigits: 1)   // 12,34,567
        /// ```
        case digits(
            primary: GroupingSize,
            secondary: GroupingSize,
            separator: GroupingSeparator,
            minGroupingDigits: MinGroupingDigits
        )
    }

    /// How the accounting sign strategy marks a negative amount.
    @usableFromInline
    package enum AccountingNegative: Equatable, Hashable, Sendable {
        /// Wrap the amount in parentheses, e.g. `($1,234.56)`.
        case parentheses
        /// Prefix the amount with the minus sign, e.g. `-1.234,56 €`.
        case minusSign
    }

    /// The currency symbol as the chosen presentation renders it: `"£"`, `"GBP"`, a narrow symbol, etc.
    @usableFromInline
    package let symbol: String
    /// How the locale arranges the symbol, the sign and the digits.
    @usableFromInline
    package let pattern: MoneyFormatPattern
    /// What separates the symbol from the digits, e.g. `""` or a non-breaking space.
    @usableFromInline
    package let currencySpacing: String
    /// What separates the whole part from the fraction, e.g. `"."` or `","`.
    @usableFromInline
    package let decimalSeparator: String
    /// How the whole digits are grouped.
    @usableFromInline
    package let grouping: GroupingScheme
    /// What marks a negative amount under the automatic/always sign strategies. Defaults to `"-"`.
    @usableFromInline
    package let minusSign: String
    /// What marks a non-negative amount under the always sign strategy. Defaults to `"+"`.
    @usableFromInline
    package let plusSign: String
    /// The glyphs the digits are rendered with: ASCII by default, or a locale's own set.
    @usableFromInline
    package let digits: Digits

    package init(
        symbol: String,
        pattern: MoneyFormatPattern,
        currencySpacing: String = "",
        decimalSeparator: String = ".",
        grouping: GroupingScheme = .repeating(3, separator: ","),
        minusSign: String = "-",
        plusSign: String = "+",
        digits: Digits = .ascii
    ) {
        self.symbol = symbol
        self.pattern = pattern
        self.currencySpacing = currencySpacing
        self.decimalSeparator = decimalSeparator
        self.grouping = grouping
        self.minusSign = minusSign
        self.plusSign = plusSign
        self.digits = digits
    }
}

package extension MoneyFormat.GroupingScheme {
    /// A grouping that repeats one `size` for every group, which is how most locales group. Defaults to a
    /// `minGroupingDigits` of one, so grouping shows as soon as there is more than one group.
    ///
    /// ```swift
    /// .repeating(3, separator: ",")   // 1,234,567
    /// ```
    static func repeating(
        _ size: GroupingSize,
        separator: GroupingSeparator,
        minGroupingDigits: MinGroupingDigits = 1
    ) -> Self {
        .digits(primary: size, secondary: size, separator: separator, minGroupingDigits: minGroupingDigits)
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

        let amountSign = Sign(of: value)
        let magnitude = value.magnitude
        let unit = UInt64.powerOfTen(digitsShown)
        let whole = digitsShown == 0 ? magnitude : magnitude / unit
        let fraction = digitsShown == 0 ? 0 : magnitude % unit

        let wholeDigits = MoneyFormat.digitCount(whole)
        let bytesPerDigit = digits.bytesPerDigit
        // The grouping to apply, or `nil` to write the whole part ungrouped: the format has no grouping
        // scheme, the caller turned grouping off, or the number is too short to reach a group boundary.
        let groups: (primary: Int, secondary: Int, separator: String)?
        switch (grouping, options.grouping) {
        case (.digits(let p, let s, let sep, let threshold), .automatic) where wholeDigits >= p.rawValue + threshold.rawValue:
            groups = (p.rawValue, s.rawValue, sep.rawValue)
        default:
            groups = nil
        }
        let separators = groups.map { 1 + (wholeDigits - $0.primary - 1) / $0.secondary } ?? 0
        let showsSeparator = digitsShown > 0 || options.decimalSeparator == .always

        let affixes = pattern.affixes(for: amountSign, sign: options.sign)
        let sign = signText(for: amountSign, strategy: options.sign)

        // The digits, their grouping separators, and the decimal separator with the fraction when both
        // are shown: the body every affix wraps, always in this order. A non-ASCII digit set is wider
        // than one byte, so the digit count is scaled by the set's uniform width (one, for ASCII).
        let separatorBytes = separators * (groups?.separator.utf8.count ?? 0)
        let decimalBytes = showsSeparator ? decimalSeparator.utf8.count : 0
        let bodyLength = (wholeDigits + digitsShown) * bytesPerDigit + separatorBytes + decimalBytes

        var length = bodyLength
        for token in affixes.prefix {
            length += self.length(of: token, sign: sign)
        }
        for token in affixes.suffix {
            length += self.length(of: token, sign: sign)
        }

        return String(unsafeUninitializedCapacity: length) { buffer in
            var offset = 0

            for token in affixes.prefix {
                offset = write(token, sign: sign, into: buffer, at: offset)
            }

            offset = writeGroupedWhole(whole, digits: wholeDigits, groups: groups, into: buffer, at: offset)
            if showsSeparator {
                offset = MoneyFormat.copy(decimalSeparator, into: buffer, at: offset)
            }
            if digitsShown > 0 {
                offset = writeDigits(fraction, count: digitsShown, into: buffer, at: offset)
            }

            for token in affixes.suffix {
                offset = write(token, sign: sign, into: buffer, at: offset)
            }

            return offset
        }
    }

    // How many bytes a token writes, so the buffer is sized exactly before anything is written.
    @inlinable
    package func length(of token: MoneyFormatToken, sign: String) -> Int {
        switch token {
        case .sign: sign.utf8.count
        case .currency: symbol.utf8.count
        case .currencySpacing: currencySpacing.utf8.count
        case .literal(let text): text.utf8.count
        }
    }

    // Writes one token into the buffer, returning the offset just past it.
    @inlinable
    package func write(
        _ token: MoneyFormatToken,
        sign: String,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        switch token {
        case .sign: MoneyFormat.copy(sign, into: buffer, at: offset)
        case .currency: MoneyFormat.copy(symbol, into: buffer, at: offset)
        case .currencySpacing: MoneyFormat.copy(currencySpacing, into: buffer, at: offset)
        case .literal(let text): MoneyFormat.copy(text, into: buffer, at: offset)
        }
    }

    // What the sign slot writes. A pattern that marks a negative another way, such as with accounting
    // parentheses, carries no sign part, so this never reaches the output there.
    @inlinable
    package func signText(for amountSign: Sign, strategy: MoneyFormatOptions.Sign) -> String {
        switch strategy {
        case .never:
            ""
        case .always:
            amountSign == .negative ? minusSign : plusSign
        case .automatic, .accounting:
            amountSign == .negative ? minusSign : ""
        }
    }

    // The whole part, most significant digit first. With `groups`, inserts the separator before a digit
    // whenever the digits from it rightward complete a group: a separator precedes MSB-digit `i` when
    // `(digits - i - primary)` is a non-negative multiple of `secondary`, giving both the uniform
    // `1,234,567` and Indian `12,34,567` shapes. Without `groups`, the digits are written plain. Each digit
    // is `glyphs` or, when that is `nil`, a plain ASCII byte. Returns the offset just past the whole part.
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

            next = writeDigit(UInt8(remaining / divisor), into: buffer, at: next)
            remaining %= divisor
            divisor /= 10
        }

        return next
    }

    // Writes one digit's value into the buffer, returning the offset just past it: a plain ASCII byte on
    // the default path, or the locale's own glyph otherwise.
    @inlinable
    func writeDigit(
        _ value: UInt8,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        switch digits {
        case .ascii:
            buffer[offset] = value &+ UInt8(ascii: "0")
            return offset + 1
        case .glyphs(let glyphs):
            return MoneyFormat.writeScalar(glyphs[Int(value)], into: buffer, at: offset)
        }
    }

    // Writes one Unicode scalar's UTF8 bytes into the buffer, returning the offset just past them.
    @inlinable
    static func writeScalar(
        _ scalar: Unicode.Scalar,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var next = offset
        UTF8.encode(scalar) { byte in
            buffer[next] = byte
            next += 1
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

    // The fraction, zero padded to `count` digits, most significant first, in the format's digits. Returns
    // the offset just past.
    @inlinable
    func writeDigits(
        _ value: UInt64,
        count: Int,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var next = offset
        var divisor = UInt64.powerOfTen(count - 1)
        var remaining = value

        while divisor > 0 {
            next = writeDigit(UInt8(remaining / divisor), into: buffer, at: next)
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

package extension MoneyFormat {
    /// The amount as an ordered list of typed runs: the same layout ``format(_:)`` renders, with the
    /// sign, currency, digits, separators and literals kept apart so a caller can tag each. A piece
    /// with no text is left out, and concatenating the runs' text gives exactly ``format(_:)``'s
    /// string. This is the seam a Foundation `AttributedString` renderer walks.
    func runs<C: CurrencyRepresentation>(_ money: MoneyOf<C>, options: MoneyFormatOptions) -> [MoneyFormatRun] {
        let places = money.currency.unitScale.decimalPlaces
        let digitsShown: Int
        let rounding: RoundingRule
        switch options.precision {
        case .currencyScale:
            (digitsShown, rounding) = (places, .toNearestOrEven)
        case .fixed(let length, let rule):
            (digitsShown, rounding) = (length.rawValue, rule)
        }
        let value = MoneyFormat.displayValue(
            money.minorUnits, scalePlaces: places, showing: digitsShown, rounding: rounding
        )

        let amountSign = Sign(of: value)
        let magnitude = value.magnitude
        let unit = UInt64.powerOfTen(digitsShown)
        let whole = digitsShown == 0 ? magnitude : magnitude / unit
        let fraction = digitsShown == 0 ? 0 : magnitude % unit
        let wholeDigits = MoneyFormat.digitCount(whole)

        let groups: (primary: Int, secondary: Int, separator: String)?
        switch (grouping, options.grouping) {
        case (.digits(let p, let s, let sep, let threshold), .automatic) where wholeDigits >= p.rawValue + threshold.rawValue:
            groups = (p.rawValue, s.rawValue, sep.rawValue)
        default:
            groups = nil
        }
        let showsSeparator = digitsShown > 0 || options.decimalSeparator == .always

        let affixes = pattern.affixes(for: amountSign, sign: options.sign)
        let sign = signText(for: amountSign, strategy: options.sign)

        var result: [MoneyFormatRun] = []
        for token in affixes.prefix {
            appendToken(token, sign: sign, into: &result)
        }
        appendInteger(whole, digits: wholeDigits, groups: groups, into: &result)
        if showsSeparator {
            result.append(.decimalSeparator(decimalSeparator))
        }
        if digitsShown > 0 {
            result.append(.fractionDigits(digitsString(fraction, count: digitsShown)))
        }
        for token in affixes.suffix {
            appendToken(token, sign: sign, into: &result)
        }
        return result
    }

    // Maps one affix token to a run, dropping a piece that has no text.
    private func appendToken(_ token: MoneyFormatToken, sign: String, into runs: inout [MoneyFormatRun]) {
        switch token {
        case .sign where !sign.isEmpty: runs.append(.sign(sign))
        case .currency where !symbol.isEmpty: runs.append(.currency(symbol))
        case .currencySpacing where !currencySpacing.isEmpty: runs.append(.currencySpacing(currencySpacing))
        case .literal(let text) where !text.isEmpty: runs.append(.literal(text))
        default: break
        }
    }

    // The whole digits as integer-digit runs divided by grouping-separator runs, placing a separator
    // by the same rule as `writeGroupedWhole`: before most-significant digit `i` when
    // `(digits - i - primary)` is a non-negative multiple of `secondary`.
    private func appendInteger(
        _ whole: UInt64,
        digits: Int,
        groups: (primary: Int, secondary: Int, separator: String)?,
        into runs: inout [MoneyFormatRun]
    ) {
        var group = ""
        var divisor = UInt64.powerOfTen(digits - 1)
        var remaining = whole

        for index in 0 ..< digits {
            if index > 0, let groups {
                let rightOf = digits - index - groups.primary
                if rightOf >= 0, rightOf % groups.secondary == 0 {
                    runs.append(.integerDigits(group))
                    runs.append(.groupingSeparator(groups.separator))
                    group = ""
                }
            }
            appendDigit(UInt8(remaining / divisor), to: &group)
            remaining %= divisor
            divisor /= 10
        }
        runs.append(.integerDigits(group))
    }

    // Appends one digit's value to a run's text: an ASCII character on the default path, or the locale's
    // own glyph.
    private func appendDigit(_ value: UInt8, to string: inout String) {
        switch digits {
        case .ascii:
            string.append(Character(UnicodeScalar(value &+ UInt8(ascii: "0"))))
        case .glyphs(let glyphs):
            string.unicodeScalars.append(glyphs[Int(value)])
        }
    }

    // `count` digits of `value`, zero-padded, most significant first.
    func digitsString(_ value: UInt64, count: Int) -> String {
        var glyphs = [String](repeating: "", count: count)
        var remaining = value
        var index = count - 1
        while index >= 0 {
            appendDigit(UInt8(remaining % 10), to: &glyphs[index])
            remaining /= 10
            index -= 1
        }
        return glyphs.joined()
    }
}

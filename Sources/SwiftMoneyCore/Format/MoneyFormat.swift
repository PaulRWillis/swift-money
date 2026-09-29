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

    /// A pattern and grouping bundled together, for a presentation the accounting sign strategy
    /// renders differently enough that it needs both — not just a different negative affix.
    @usableFromInline
    package struct Arrangement: Equatable, Hashable, Sendable {
        @usableFromInline
        package let pattern: MoneyFormatPattern
        @usableFromInline
        package let grouping: GroupingScheme

        package init(pattern: MoneyFormatPattern, grouping: GroupingScheme) {
            self.pattern = pattern
            self.grouping = grouping
        }
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
    /// The pattern and grouping the accounting sign strategy renders a **non-negative** amount with,
    /// when that differs from ``pattern``/``grouping`` by more than the negative affix (which
    /// ``MoneyFormatPattern/accountingNegative`` already carries). `nil` — the common case — means
    /// accounting renders exactly like the standard presentation but for its negative affix, so the
    /// standard `pattern`/`grouping` serve every sign strategy unchanged.
    @usableFromInline
    package let accountingArrangement: Arrangement?

    package init(
        symbol: String,
        pattern: MoneyFormatPattern,
        currencySpacing: String = "",
        decimalSeparator: String = ".",
        grouping: GroupingScheme = .repeating(3, separator: ","),
        minusSign: String = "-",
        plusSign: String = "+",
        digits: Digits = .ascii,
        accountingArrangement: Arrangement? = nil
    ) {
        self.symbol = symbol
        self.pattern = pattern
        self.currencySpacing = currencySpacing
        self.decimalSeparator = decimalSeparator
        self.grouping = grouping
        self.minusSign = minusSign
        self.plusSign = plusSign
        self.digits = digits
        self.accountingArrangement = accountingArrangement
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
        let scalePlaces = UInt64.DecimalExponent(money.currency.unitScale)
        let places = Int(scalePlaces)
        let digitsShown: Int
        let shown: UInt64.DecimalExponent
        let rounding: RoundingRule
        switch options.precision {
        case .currencyScale:
            // Shows every digit the currency divides into, so nothing is dropped and rounding is moot.
            (digitsShown, shown, rounding) = (places, scalePlaces, .toNearestOrEven)
        case .fixed(let length, let rule):
            (digitsShown, shown, rounding) = (length.rawValue, UInt64.DecimalExponent(length), rule)
        }
        let value = MoneyFormat.displayValue(
            money.minorUnits, scalePlaces: places, showing: digitsShown, rounding: rounding
        )

        let amountSign = Sign(of: value)
        let wideMagnitude = value.magnitude
        let unit = UInt64.powerOfTen(shown)
        // Splitting by `unit` (a `UInt64`) always brings each half back within `UInt64`'s range, even
        // when the combined `wideMagnitude` needed more than 64 bits to hold.
        guard let whole = UInt64(exactly: digitsShown == 0 ? wideMagnitude : wideMagnitude / UInt128(unit)),
              let fraction = UInt64(exactly: digitsShown == 0 ? 0 : wideMagnitude % UInt128(unit)) else {
            preconditionFailure("Formatted amount is out of the display engine's range")  // coverage:ignore — exit-test trap
        }

        let leadingDigit = UInt64.DecimalExponent(leadingDigitOf: whole)
        let wholeDigits = Int(leadingDigit) + 1
        let bytesPerDigit = digits.bytesPerDigit

        // Under `.accounting`, an arrangement that moves the side (or grouping) for a non-negative
        // amount takes over both; every other sign strategy, `accountingArrangement == nil`, and a
        // negative amount (whose affix already comes from `pattern.accountingNegative`) fall through
        // to the standard fields. A `switch` on the pair, rather than a ternary feeding `??`, is the
        // shape that measured no cost on this path: a ternary-and-coalesce over a `MoneyFormatPattern`
        // (array-backed) still forced the optimizer to materialize both branches' value.
        let pattern: MoneyFormatPattern
        let grouping: GroupingScheme
        switch (options.sign, accountingArrangement) {
        case (.accounting, .some(let arrangement)):
            pattern = arrangement.pattern
            grouping = arrangement.grouping
        default:
            pattern = self.pattern
            grouping = self.grouping
        }

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

            offset = writeGroupedWhole(whole, from: leadingDigit, groups: groups, into: buffer, at: offset)
            if showsSeparator {
                offset = MoneyFormat.copy(decimalSeparator, into: buffer, at: offset)
            }
            if digitsShown > 0 {
                // `unit` is ten to `digitsShown`, so this writes `digitsShown` digits.
                offset = writeDigits(fraction, from: unit / 10, into: buffer, at: offset)
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
        case .directionalMark(let mark): String(mark.scalar).utf8.count
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
        case .directionalMark(let mark): MoneyFormat.writeScalar(mark.scalar, into: buffer, at: offset)
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
    internal func writeGroupedWhole(
        _ whole: UInt64,
        from leadingDigit: UInt64.DecimalExponent,
        groups: (primary: Int, secondary: Int, separator: String)?,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        let digits = Int(leadingDigit) + 1
        var next = offset
        var divisor = UInt64.powerOfTen(leadingDigit)
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
    internal func writeDigit(
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
    internal static func writeScalar(
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
    internal static func copy(
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

    // The fraction, most significant digit first, from the place `divisor` counts down to the units, in
    // the format's digits. Returns the offset just past.
    @inlinable
    internal func writeDigits(
        _ value: UInt64,
        from divisor: UInt64,
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var next = offset
        var divisor = divisor
        var remaining = value

        while divisor > 0 {
            next = writeDigit(UInt8(remaining / divisor), into: buffer, at: next)
            remaining %= divisor
            divisor /= 10
        }

        return next
    }

    // The minor-unit count re-expressed at `showing` fraction digits: unchanged when that equals the
    // currency's scale, padded (× a power of ten) when it is more, and rounded by `rounding` when it is
    // fewer. The result counts `10 ^ showing` per major unit.
    //
    // Widened to `Int128` because padding can need more than 64 bits to hold the whole and padded
    // fraction combined, even though each half (once split by `unit` at the call site) always fits back
    // into `UInt64` on its own. `Int64(minorUnits)` magnitude times `UInt64.powerOfTen`'s own ceiling
    // never comes close to overflowing `Int128`, so this multiply is never truly at risk.
    @inlinable
    package static func displayValue(
        _ minorUnits: Int64,
        scalePlaces: Int,
        showing: Int,
        rounding: RoundingRule
    ) -> Int128 {
        if showing == scalePlaces {
            return Int128(minorUnits)
        }

        if showing > scalePlaces {
            return Int128(minorUnits) * Int128(UInt64.powerOfTen(placesBetween(showing, scalePlaces)))
        }
        let divisor = UInt64.powerOfTen(placesBetween(scalePlaces, showing))
        return Int128(roundedQuotient(minorUnits, by: Int64(divisor), rule: rounding))
    }

    // How many places `more` is past `fewer`. Both count fraction digits, `0...19`, so the difference
    // always has a power of ten in a `UInt64`.
    @inlinable
    internal static func placesBetween(_ more: Int, _ fewer: Int) -> UInt64.DecimalExponent {
        guard let places = UInt64.DecimalExponent(exactly: more - fewer) else {
            preconditionFailure("Fraction digit counts differ by more than 19")  // coverage:ignore — unreachable
        }

        return places
    }

    // `value / divisor`, rounded to a whole quotient by `rule`. Self-contained (no wide-int helpers) so
    // it stays inlinable. `divisor` is a positive power of ten.
    @inlinable
    internal static func roundedQuotient(_ value: Int64, by divisor: Int64, rule: RoundingRule) -> Int64 {
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
        let scalePlaces = UInt64.DecimalExponent(money.currency.unitScale)
        let places = Int(scalePlaces)
        let digitsShown: Int
        let shown: UInt64.DecimalExponent
        let rounding: RoundingRule
        switch options.precision {
        case .currencyScale:
            (digitsShown, shown, rounding) = (places, scalePlaces, .toNearestOrEven)
        case .fixed(let length, let rule):
            (digitsShown, shown, rounding) = (length.rawValue, UInt64.DecimalExponent(length), rule)
        }
        let value = MoneyFormat.displayValue(
            money.minorUnits, scalePlaces: places, showing: digitsShown, rounding: rounding
        )

        let amountSign = Sign(of: value)
        let wideMagnitude = value.magnitude
        let unit = UInt64.powerOfTen(shown)
        // Splitting by `unit` (a `UInt64`) always brings each half back within `UInt64`'s range, even
        // when the combined `wideMagnitude` needed more than 64 bits to hold.
        guard let whole = UInt64(exactly: digitsShown == 0 ? wideMagnitude : wideMagnitude / UInt128(unit)),
              let fraction = UInt64(exactly: digitsShown == 0 ? 0 : wideMagnitude % UInt128(unit)) else {
            preconditionFailure("Formatted amount is out of the display engine's range")  // coverage:ignore — exit-test trap
        }
        let leadingDigit = UInt64.DecimalExponent(leadingDigitOf: whole)
        let wholeDigits = Int(leadingDigit) + 1

        // See `format(_:options:)` for why this reads the accounting arrangement only under
        // `.accounting`, and only when one is present, and for why a `switch` rather than a ternary.
        let pattern: MoneyFormatPattern
        let grouping: GroupingScheme
        switch (options.sign, accountingArrangement) {
        case (.accounting, .some(let arrangement)):
            pattern = arrangement.pattern
            grouping = arrangement.grouping
        default:
            pattern = self.pattern
            grouping = self.grouping
        }

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
        appendInteger(whole, from: leadingDigit, groups: groups, into: &result)
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
        case .directionalMark(let mark): runs.append(.directionalMark(mark))
        default: break
        }
    }

    // The whole digits as integer-digit runs divided by grouping-separator runs, placing a separator
    // by the same rule as `writeGroupedWhole`: before most-significant digit `i` when
    // `(digits - i - primary)` is a non-negative multiple of `secondary`.
    private func appendInteger(
        _ whole: UInt64,
        from leadingDigit: UInt64.DecimalExponent,
        groups: (primary: Int, secondary: Int, separator: String)?,
        into runs: inout [MoneyFormatRun]
    ) {
        let digits = Int(leadingDigit) + 1
        var group = ""
        var divisor = UInt64.powerOfTen(leadingDigit)
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

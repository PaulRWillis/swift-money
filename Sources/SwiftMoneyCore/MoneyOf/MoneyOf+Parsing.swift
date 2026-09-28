public extension MoneyOf where C: CurrencyType {
    /// Creates an amount from a string, in the currency this type names.
    ///
    /// ```swift
    /// GBP(string: "4.99")                        // £4.99
    /// GBP(string: "499")                         // £4.99, the same amount in pence
    /// GBP(string: "15", units: .majorUnits)      // £15.00
    /// GBP(string: "GBP 4.99")                    // £4.99
    /// GBP(string: "USD 4.99")                    // nil
    /// ```
    ///
    /// A `.` always means major units. Digits without one count the units named, the currency's
    /// smallest unless told otherwise. The code may be left out, this type having named the currency
    /// already, and must match where it is given.
    ///
    /// - Parameters:
    ///   - string: The amount, with or without its currency code.
    ///   - units: Which units digits without a `.` count.
    /// - Returns: `nil` unless the string is an amount this currency can hold exactly.
    @inlinable
    init?(
        string: String,
        units: MoneyCodingUnits = .minorUnits
    ) {
        guard let minorUnits = parsedMinorUnits(string, in: C.currency, units: units) else {
            return nil
        }

        self.init(unchecked: minorUnits, storage: .implied)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Creates an amount from a string naming an ISO 4217 currency.
    ///
    /// ```swift
    /// Money(string: "GBP 4.99")                     // £4.99
    /// Money(string: "GBP 499")                      // £4.99, the same amount in pence
    /// Money(string: "GBP 15", units: .majorUnits)   // £15.00
    /// Money(string: "JPY 499")                      // ¥499
    /// Money(string: "LTY 250")                      // nil
    /// Money(string: "4.99")                         // nil
    /// ```
    ///
    /// A `.` always means major units. Digits without one count the units named, the currency's
    /// smallest unless told otherwise. The code is required, nothing else here being able to say how
    /// finely the currency divides. Use ``init(string:currency:units:)`` for a currency outside
    /// ISO 4217.
    ///
    /// - Parameters:
    ///   - string: The amount, led by its currency code.
    ///   - units: Which units digits without a `.` count.
    /// - Returns: `nil` unless the string is an amount an ISO 4217 currency can hold exactly.
    init?(
        string: String,
        units: MoneyCodingUnits = .minorUnits
    ) {
        guard let parsed = parsedISOAmount(string, units: units) else {
            return nil
        }

        self.init(unchecked: parsed.minorUnits, storage: parsed.currency)
    }

    /// Creates an amount from a string, in a currency the caller names.
    ///
    /// ```swift
    /// let points = Currency(code: "LTY", unitScale: 1)   // Currency?
    ///
    /// if let points {
    ///     Money(string: "250", currency: points)       // 250 points
    ///     Money(string: "LTY 250", currency: points)   // 250 points
    ///     Money(string: "GBP 250", currency: points)   // nil
    /// }
    /// ```
    ///
    /// A `.` always means major units. Digits without one count the units named, the currency's
    /// smallest unless told otherwise. The code may be left out, the argument having named the
    /// currency already, and must match where it is given.
    ///
    /// - Parameters:
    ///   - string: The amount, with or without its currency code.
    ///   - currency: The currency the amount is in.
    ///   - units: Which units digits without a `.` count.
    /// - Returns: `nil` unless the string is an amount that currency can hold exactly.
    init?(
        string: String,
        currency: Currency,
        units: MoneyCodingUnits = .minorUnits
    ) {
        guard let minorUnits = parsedMinorUnits(string, in: currency, units: units) else {
            return nil
        }

        self.init(unchecked: minorUnits, storage: currency)
    }
}

// The amount a string holds, in the smallest units of a currency the caller already knows. A code is
// optional and must agree with that currency where it is given.
@usableFromInline
func parsedMinorUnits(
    _ string: String,
    in currency: Currency,
    units: MoneyCodingUnits
) -> Int64? {
    let scale = UInt64(Int64(currency.unitScale))
    let scanned = string.withUTF8Buffer { utf8 -> ScannedAmount? in
        let (code, digits) = codeAndDigits(utf8)

        guard code == nil || code == currency.code else {
            return nil
        }

        return ScannedAmount(digits, scale: scale)
    }

    return scanned?.minorUnits(in: currency, units: units)
}

// The amount and currency a string holds, the code naming an ISO 4217 currency. The code is required,
// nothing else here being able to say how finely the currency divides.
@usableFromInline
func parsedISOAmount(
    _ string: String,
    units: MoneyCodingUnits
) -> (minorUnits: Int64, currency: Currency)? {
    let scanned = string.withUTF8Buffer { utf8 -> (ScannedAmount, Currency)? in
        let (code, digits) = codeAndDigits(utf8)

        guard let code,
              let currency = Currency(iso: code),
              let amount = ScannedAmount(digits, scale: UInt64(Int64(currency.unitScale)))
        else {
            return nil
        }

        return (amount, currency)
    }

    guard let (amount, currency) = scanned,
          let minorUnits = amount.minorUnits(in: currency, units: units)
    else {
        return nil
    }

    return (minorUnits, currency)
}

extension MoneyOf {
    // The amount a coded string holds, the currency coming from the code where the string names one
    // and from the representation where it does not. One implementation for both money types, since
    // `Codable` may be conformed to only once.
    init(
        codedString text: String,
        units: MoneyCodingUnits
    ) throws(CodedStringError) {
        switch Self.parsed(codedString: text, units: units) {
        case let .success(amount):
            self.init(unchecked: amount.minorUnits, storage: amount.storage)

        case let .failure(error):
            throw error
        }
    }

    private static func parsed(
        codedString text: String,
        units: MoneyCodingUnits
    ) -> Result<(minorUnits: Int64, storage: C.Storage), CodedStringError> {
        text.withUTF8Buffer { utf8 in
            let (code, digits) = codeAndDigits(utf8)

            guard let storage = C.storage(forCode: code) else {
                return .failure(code.map { .unresolvedCurrency($0) } ?? .unnamedCurrency)
            }

            let currency = C.currency(for: storage)

            guard let amount = ScannedAmount(digits, scale: UInt64(Int64(currency.unitScale))),
                  let minorUnits = amount.minorUnits(in: currency, units: units)
            else {
                return .failure(.inexactAmount(currency))
            }

            return .success((minorUnits, storage))
        }
    }
}

private extension String {
    // The bytes, lent where they are already contiguous UTF-8 and copied where they are not.
    func withUTF8Buffer<T>(_ body: (UnsafeBufferPointer<UInt8>) -> T) -> T {
        utf8.withContiguousStorageIfAvailable(body) ?? Array(utf8).withUnsafeBufferPointer(body)
    }
}

// The code a string leads with and the digits that follow. Where no code is found the whole string
// is digits, which is the form a caller who already knows the currency may use.
private func codeAndDigits(
    _ utf8: UnsafeBufferPointer<UInt8>
) -> (code: CurrencyCode?, digits: Slice<UnsafeBufferPointer<UInt8>>) {
    guard let leading = CurrencyCode.leading(in: utf8) else {
        return (nil, utf8[...])
    }

    return (leading.code, utf8[leading.after...])
}

// Digits as a scan read them, before anything says which units digits without a point count. A
// point always means major units, so those the scan has already brought to the smallest.
//
// Units are applied after the scan, outside the closure that lends it the bytes: capturing them in
// that closure cost every parse of a coded string twelve instructions.
private enum ScannedAmount {
    // Written without a point, so counting whichever units the caller names.
    case whole(Int64)

    // Written with a point, and already in the smallest units.
    case fractional(Int64)

    // The amount in the smallest units, digits without a point counting `units`. `nil` where
    // scaling whole major units carries them past the range.
    //
    // Takes the currency rather than its scale, which costs a table read, so that only the one case
    // needing the scale pays for it.
    func minorUnits(
        in currency: Currency,
        units: MoneyCodingUnits
    ) -> Int64? {
        switch (self, units) {
        case let (.fractional(amount), _), let (.whole(amount), .minorUnits):
            return amount

        case let (.whole(amount), .majorUnits):
            let (product, overflow) = amount.multipliedReportingOverflow(by: Int64(currency.unitScale))

            return overflow ? nil : product
        }
    }
}

extension ScannedAmount {
    // The amount a run of bytes holds, digits without a point counting smallest units until the
    // caller says otherwise. One pass: the point is met rather than searched for, and the power of
    // ten it implies is accumulated alongside the digits it counts.
    init?(
        _ utf8: Slice<UnsafeBufferPointer<UInt8>>,
        scale: UInt64
    ) {
        var whole: UInt64 = 0
        var fraction: UInt64 = 0
        var power: UInt64 = 1
        var isNegative = false
        var seenPoint = false
        var seenDigit = false
        var index = utf8.startIndex

        if index < utf8.endIndex, utf8[index] == UInt8(ascii: "-") || utf8[index] == UInt8(ascii: "+") {
            isNegative = utf8[index] == UInt8(ascii: "-")
            index = utf8.index(after: index)
        }

        while index < utf8.endIndex {
            let byte = utf8[index]
            index = utf8.index(after: index)

            if byte == UInt8(ascii: ".") {
                guard !seenPoint else {
                    return nil
                }

                seenPoint = true
                seenDigit = false
                continue
            }

            let digit = UInt64(byte &- UInt8(ascii: "0"))

            guard digit < 10 else {
                return nil
            }

            seenDigit = true

            if seenPoint {
                guard let raised = power.multipliedExactly(by: 10),
                      let shifted = fraction.multipliedExactly(by: 10),
                      let added = shifted.addedExactly(digit)
                else {
                    return nil
                }

                power = raised
                fraction = added
            } else {
                guard let shifted = whole.multipliedExactly(by: 10),
                      let added = shifted.addedExactly(digit)
                else {
                    return nil
                }

                whole = added
            }
        }

        guard seenDigit else {
            return nil
        }

        // Without a point nothing is scaled yet: the caller says which units the digits count.
        guard seenPoint else {
            guard let amount = Int64(magnitude: whole, sign: isNegative ? .negative : .positive) else {
                return nil
            }

            self = .whole(amount)
            return
        }

        guard let scaledFraction = fraction.scaled(by: scale, over: power),
              let major = whole.multipliedExactly(by: scale),
              let magnitude = major.addedExactly(scaledFraction)
        else {
            return nil
        }

        guard let amount = Int64(magnitude: magnitude, sign: isNegative ? .negative : .positive) else {
            return nil
        }

        self = .fractional(amount)
    }
}

private extension UInt64 {
    // `self * scale / power`, where `self` is a fraction below `power`. `nil` where the division
    // leaves a remainder, the string then being finer than the currency divides, as "GBP 4.999" is:
    // rounding it away here would be losing money quietly.
    //
    // Multiplying first is right until it overflows, which eighteen fraction digits reach. That is
    // not an exotic input: a sender padding "4.99" to eighteen places is writing an amount sterling
    // holds exactly, and it used to be refused.
    func scaled(
        by scale: UInt64,
        over power: UInt64
    ) -> UInt64? {
        let (product, overflow) = multipliedReportingOverflow(by: scale)

        guard overflow else {
            return product.isMultiple(of: power) ? product / power : nil
        }

        return reduced(by: scale, over: power)
    }

    // Out of line so that the caller above stays small enough to inline: holding this beside it cost
    // every parse sixteen instructions, for a branch almost nothing takes.
    @inline(never)
    func reduced(
        by scale: UInt64,
        over power: UInt64
    ) -> UInt64? {
        // Reducing the two before multiplying holds every intermediate below `scale`, the fraction
        // being below `power`.
        let common = greatestCommonDivisor(of: power, and: scale)
        let divisor = power / common

        return isMultiple(of: divisor) ? self / divisor * (scale / common) : nil
    }

    func multipliedExactly(by other: UInt64) -> UInt64? {
        let (product, overflow) = multipliedReportingOverflow(by: other)

        return overflow ? nil : product
    }

    func addedExactly(_ other: UInt64) -> UInt64? {
        let (sum, overflow) = addingReportingOverflow(other)

        return overflow ? nil : sum
    }
}

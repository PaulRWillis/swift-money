public extension MoneyOf where C: CurrencyType {
    /// Creates an amount from a string, in the currency this type names.
    ///
    /// ```swift
    /// GBP(string: "4.99")       // £4.99
    /// GBP(string: "499")        // £4.99, the same amount in pence
    /// GBP(string: "GBP 4.99")   // £4.99
    /// GBP(string: "USD 4.99")   // nil
    /// ```
    ///
    /// A `.` means major units and no `.` means the currency's smallest units. The code may be left
    /// out, this type having named the currency already, and must match where it is given.
    ///
    /// - Parameter string: The amount, with or without its currency code.
    /// - Returns: `nil` unless the string is an amount this currency can hold exactly.
    @inlinable
    init?(string: String) {
        guard let minorUnits = parsedMinorUnits(string, in: C.currency) else {
            return nil
        }

        self.init(unchecked: minorUnits, storage: .implied)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Creates an amount from a string naming an ISO 4217 currency.
    ///
    /// ```swift
    /// Money(string: "GBP 4.99")   // £4.99
    /// Money(string: "GBP 499")    // £4.99, the same amount in pence
    /// Money(string: "JPY 499")    // ¥499
    /// Money(string: "LTY 250")    // nil
    /// Money(string: "4.99")       // nil
    /// ```
    ///
    /// A `.` means major units and no `.` means the currency's smallest units. The code is required,
    /// nothing else here being able to say how finely the currency divides. Use
    /// ``init(string:currency:)`` for a currency outside ISO 4217.
    ///
    /// - Parameter string: The amount, led by its currency code.
    /// - Returns: `nil` unless the string is an amount an ISO 4217 currency can hold exactly.
    init?(string: String) {
        guard let parsed = parsedISOAmount(string) else {
            return nil
        }

        self.init(unchecked: parsed.minorUnits, storage: parsed.currency)
    }

    /// Creates an amount from a string, in a currency the caller names.
    ///
    /// ```swift
    /// let points = Currency(code: "LTY", unitScale: 1)
    ///
    /// Money(string: "250", currency: points)       // 250 points
    /// Money(string: "LTY 250", currency: points)   // 250 points
    /// Money(string: "GBP 250", currency: points)   // nil
    /// ```
    ///
    /// A `.` means major units and no `.` means the currency's smallest units. The code may be left
    /// out, the argument having named the currency already, and must match where it is given.
    ///
    /// - Parameters:
    ///   - string: The amount, with or without its currency code.
    ///   - currency: The currency the amount is in.
    /// - Returns: `nil` unless the string is an amount that currency can hold exactly.
    init?(
        string: String,
        currency: Currency
    ) {
        guard let minorUnits = parsedMinorUnits(string, in: currency) else {
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
    in currency: Currency
) -> Int64? {
    var string = string

    return string.withUTF8 { utf8 in
        guard let (code, digits) = codeAndDigits(utf8), code == nil || code == currency.code else {
            return nil
        }

        return minorUnits(digits, scale: UInt64(Int64(currency.unitScale)))
    }
}

// The amount and currency a string holds, the code naming an ISO 4217 currency. The code is required,
// nothing else here being able to say how finely the currency divides.
@usableFromInline
func parsedISOAmount(_ string: String) -> (minorUnits: Int64, currency: Currency)? {
    var string = string

    return string.withUTF8 { utf8 -> (Int64, Currency)? in
        guard let (code, digits) = codeAndDigits(utf8),
              let code,
              let currency = Currency(iso: code),
              let minorUnits = minorUnits(digits, scale: UInt64(Int64(currency.unitScale)))
        else {
            return nil
        }

        return (minorUnits, currency)
    }
}

// Splits a string into the code it may lead with and the digits that follow, packing the code once.
@usableFromInline
func codeAndDigits(
    _ utf8: UnsafeBufferPointer<UInt8>
) -> (code: CurrencyCode?, digits: Slice<UnsafeBufferPointer<UInt8>>)? {
    guard let space = utf8.firstIndex(of: UInt8(ascii: " ")) else {
        return (nil, utf8[...])
    }

    guard let code = CurrencyCode(utf8: utf8[..<space]) else {
        return nil
    }

    return (code, utf8[utf8.index(after: space)...])
}

// The amount a run of bytes holds, in the smallest units of a currency of `scale`. One pass: the
// decimal point is met rather than searched for, and the power of ten it implies is accumulated
// alongside the digits it counts.
@usableFromInline
func minorUnits(
    _ utf8: Slice<UnsafeBufferPointer<UInt8>>,
    scale: UInt64
) -> Int64? {
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

    // Without a point the digits are already the smallest units, so nothing is scaled.
    guard seenPoint else {
        return Int64(magnitude: whole, sign: isNegative ? .negative : .positive)
    }

    guard let scaled = fraction.multipliedExactly(by: scale),
          // A remainder means the string is finer than the currency divides, as "GBP 4.999" is, and
          // rounding it away here would be losing money quietly.
          scaled.isMultiple(of: power),
          let major = whole.multipliedExactly(by: scale),
          let magnitude = major.addedExactly(scaled / power)
    else {
        return nil
    }

    return Int64(magnitude: magnitude, sign: isNegative ? .negative : .positive)
}

extension UInt64 {
    @usableFromInline
    func multipliedExactly(by other: UInt64) -> UInt64? {
        let (product, overflow) = multipliedReportingOverflow(by: other)

        return overflow ? nil : product
    }

    @usableFromInline
    func addedExactly(_ other: UInt64) -> UInt64? {
        let (sum, overflow) = addingReportingOverflow(other)

        return overflow ? nil : sum
    }

    @usableFromInline
    static func powerOfTen(exactly exponent: Int) -> UInt64? {
        var power: UInt64 = 1

        for _ in 0 ..< exponent {
            guard let raised = power.multipliedExactly(by: 10) else {
                return nil
            }

            power = raised
        }

        return power
    }
}

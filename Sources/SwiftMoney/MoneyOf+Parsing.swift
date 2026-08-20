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

@usableFromInline
func minorUnits(
    _ utf8: Slice<UnsafeBufferPointer<UInt8>>,
    scale: UInt64
) -> Int64? {
    guard !utf8.isEmpty else {
        return nil
    }

    var index = utf8.startIndex
    var isNegative = false

    switch utf8[index] {
    case UInt8(ascii: "-"):
        isNegative = true
        index = utf8.index(after: index)
    case UInt8(ascii: "+"):
        index = utf8.index(after: index)
    default:
        break
    }

    let point = utf8[index...].firstIndex(of: UInt8(ascii: "."))
    let wholeEnd = point ?? utf8.endIndex

    guard let whole = value(ofDigits: utf8[index ..< wholeEnd]) else {
        return nil
    }

    var magnitude = whole

    if let point {
        let fractionDigits = utf8[utf8.index(after: point)...]

        guard let fraction = value(ofDigits: fractionDigits),
              let power = UInt64.powerOfTen(exactly: fractionDigits.count),
              let scaled = fraction.multipliedExactly(by: scale),
              // A remainder means the string is finer than the currency divides, as "GBP 4.999" is,
              // and rounding it away here would be losing money quietly.
              scaled.isMultiple(of: power),
              let whole = magnitude.multipliedExactly(by: scale),
              let total = whole.addedExactly(scaled / power)
        else {
            return nil
        }

        magnitude = total
    }

    return Int64(magnitude: magnitude, sign: isNegative ? .negative : .positive)
}

// The value of a run of ASCII digits, or `nil` if it is empty, holds anything else, or overflows.
@usableFromInline
func value(ofDigits utf8: Slice<UnsafeBufferPointer<UInt8>>) -> UInt64? {
    guard !utf8.isEmpty else {
        return nil
    }

    var value: UInt64 = 0

    for byte in utf8 {
        let digit = byte &- UInt8(ascii: "0")

        guard digit < 10,
              let shifted = value.multipliedExactly(by: 10),
              let added = shifted.addedExactly(UInt64(digit))
        else {
            return nil
        }

        value = added
    }

    return value
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

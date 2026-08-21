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
    string.withUTF8Buffer { utf8 in
        let (code, digits) = codeAndDigits(utf8)

        guard code == nil || code == currency.code else {
            return nil
        }

        return minorUnits(digits, scale: UInt64(Int64(currency.unitScale)))
    }
}

// The amount and currency a string holds, the code naming an ISO 4217 currency. The code is required,
// nothing else here being able to say how finely the currency divides.
@usableFromInline
func parsedISOAmount(_ string: String) -> (minorUnits: Int64, currency: Currency)? {
    string.withUTF8Buffer { utf8 -> (Int64, Currency)? in
        let (code, digits) = codeAndDigits(utf8)

        guard let code,
              let currency = Currency(iso: code),
              let minorUnits = minorUnits(digits, scale: UInt64(Int64(currency.unitScale)))
        else {
            return nil
        }

        return (minorUnits, currency)
    }
}

extension MoneyOf {
    // The amount a coded string holds, the currency coming from the code where the string names one
    // and from the representation where it does not. One implementation for both money types, since
    // `Codable` may be conformed to only once.
    init?(codedString text: String) {
        guard let parsed = text.withUTF8Buffer({ utf8 -> (Int64, C.Storage)? in
            let (code, digits) = codeAndDigits(utf8)

            guard let storage = C.storage(forCode: code) else {
                return nil
            }

            let currency = C.currency(for: storage)

            // Qualified, because the stored property of the same name shadows the function here.
            guard let amount = SwiftMoney.minorUnits(
                digits,
                scale: UInt64(Int64(currency.unitScale))
            ) else {
                return nil
            }

            return (amount, storage)
        }) else {
            return nil
        }

        self.init(unchecked: parsed.0, storage: parsed.1)
    }
}

private extension String {
    // The bytes, lent where they are already contiguous UTF-8 and copied where they are not.
    func withUTF8Buffer<T>(_ body: (UnsafeBufferPointer<UInt8>) -> T?) -> T? {
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

// The amount a run of bytes holds, in the smallest units of a currency of `scale`. One pass: the
// decimal point is met rather than searched for, and the power of ten it implies is accumulated
// alongside the digits it counts.
private func minorUnits(
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

private extension UInt64 {
    func multipliedExactly(by other: UInt64) -> UInt64? {
        let (product, overflow) = multipliedReportingOverflow(by: other)

        return overflow ? nil : product
    }

    func addedExactly(_ other: UInt64) -> UInt64? {
        let (sum, overflow) = addingReportingOverflow(other)

        return overflow ? nil : sum
    }
}

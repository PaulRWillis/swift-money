// A fixed-width binary encoding of a monetary amount, for storing or transmitting money where a text
// format like `Codable` is too slow or too large — Embedded firmware persisting to flash, a ledger
// writing fixed-size records at known offsets, a wire protocol. Fifteen bytes, big-endian throughout,
// laid out amount then currency:
//
//     bytes  0 ... 7   Int64  minorUnits          (two's-complement)
//     bytes  8 ... 13  UInt48 currency code        (the code packed six bits per character)
//     byte  14         UInt8  currency scale       (decimal places, 0 ... 18)
//
// Every amount encodes to the same fifteen bytes, whatever its currency, so a record holds a fixed
// column of them. The scale travels in the bytes rather than being looked up from the code, so a
// custom currency the ISO table does not know round-trips as faithfully as a standard one.

public extension MoneyOf {
    /// The number of bytes ``bytes`` writes, and ``init(bytes:)`` reads.
    static var byteCount: Int { 15 }
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf {
    /// This amount as its fixed fifteen-byte encoding.
    ///
    /// ```swift
    /// let stored = GBP(minorUnits: 4_99).bytes   // 15 bytes, ready to write to disk or a wire
    /// ```
    ///
    /// The bytes carry the amount, the currency code, and the scale, so ``init(bytes:)`` rebuilds the
    /// amount without consulting any table. Allocation-free.
    @inlinable
    var bytes: InlineArray<15, UInt8> {
        let amount = UInt64(bitPattern: Int64(minorUnits))
        let code = currency.code.compactValue
        let scale = UInt8(currency.unitScale.decimalPlaces)

        return InlineArray<15, UInt8> { index in
            switch index {
            case 0 ... 7:
                UInt8(truncatingIfNeeded: amount >> (8 * (7 - index)))
            case 8 ... 13:
                UInt8(truncatingIfNeeded: code >> (8 * (13 - index)))
            default:
                scale
            }
        }
    }
}

// The three fields a fifteen-byte encoding carries, read out but not yet validated into a currency.
// Shared by the typed and runtime decoders, which differ only in how they turn the code and scale into
// a currency.
@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
@inlinable
func decodedMoneyFields(_ bytes: InlineArray<15, UInt8>) -> (minorUnits: Int64, code: CurrencyCode, scale: UnitScale)? {
    var amount: UInt64 = 0
    for index in 0 ... 7 {
        amount = amount << 8 | UInt64(bytes[index])
    }

    var packedCode: UInt64 = 0
    for index in 8 ... 13 {
        packedCode = packedCode << 8 | UInt64(bytes[index])
    }

    guard let code = CurrencyCode(compactValue: packedCode),
          let scale = UnitScale(decimalPlaces: Int(bytes[14])) else {
        return nil
    }

    return (Int64(bitPattern: amount), code, scale)
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf where C: CurrencyType {
    /// Rebuilds a typed amount from its fifteen-byte encoding.
    ///
    /// - Returns: `nil` unless the bytes are a valid encoding whose currency is the one this type names.
    ///   The code and scale in the bytes must match `C`'s own, so decoding `GBP` bytes as `EUR` fails.
    @inlinable
    init?(bytes: InlineArray<15, UInt8>) {
        guard let fields = decodedMoneyFields(bytes),
              fields.code == C.currency.code,
              fields.scale == C.currency.unitScale else {
            return nil
        }

        self.init(unchecked: fields.minorUnits, storage: .implied)
    }
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf where C == AnyCurrency {
    /// Rebuilds a runtime-currency amount from its fifteen-byte encoding.
    ///
    /// - Returns: `nil` unless the bytes are a valid encoding: a valid code and scale that name a
    ///   currency, and a scale the code does not contradict (a currency the library ships at a
    ///   different scale is refused).
    @inlinable
    init?(bytes: InlineArray<15, UInt8>) {
        guard let fields = decodedMoneyFields(bytes),
              let currency = Currency(code: fields.code, unitScale: fields.scale) else {
            return nil
        }

        self.init(unchecked: fields.minorUnits, storage: currency)
    }
}

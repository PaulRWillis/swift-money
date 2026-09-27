// A fixed-width binary encoding of an unrounded amount, the counterpart to `MoneyOf.bytes` for money
// held before it is settled to whole minor units — the state a ledger keeps a balance in while it
// accrues daily interest. Twenty-three bytes, big-endian throughout, laid out amount then currency:
//
//     bytes  0 ... 15   Int128  amount times 10^18   (two's-complement)
//     bytes 16 ... 21   UInt48  currency code         (the code packed six bits per character)
//     byte  22          UInt8   currency scale        (decimal places, 0 ... 18)
//
// The amount is the internal storage of the `Fixed` count of minor units — the count multiplied by
// 10^18 — so it fills most of the sixteen bytes even for a small settled amount. As with the settled
// encoding, the scale travels in the bytes, so a custom currency round-trips as faithfully as a
// shipped one.

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf.Unrounded {
    /// The number of bytes ``bytes`` writes, and ``init(bytes:)`` reads.
    static var byteCount: Int { 23 }
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf.Unrounded {
    /// This unrounded amount as its fixed twenty-three-byte encoding.
    ///
    /// ```swift
    /// let stored = balance.unrounded.bytes   // 23 bytes, ready to write to a ledger record
    /// ```
    ///
    /// The bytes carry the amount, the currency code, and the scale, so ``init(bytes:)`` rebuilds the
    /// amount without consulting any table. Allocation-free.
    @inlinable
    var bytes: InlineArray<23, UInt8> {
        let amount = UInt128(bitPattern: minorUnits.storageBits)
        let currency = C.currency(for: storage)
        let code = currency.code.compactValue
        let scale = UInt8(currency.unitScale.decimalPlaces)

        return InlineArray<23, UInt8> { index in
            switch index {
            case 0 ... 15:
                UInt8(truncatingIfNeeded: amount >> (8 * (15 - index)))
            case 16 ... 21:
                UInt8(truncatingIfNeeded: code >> (8 * (21 - index)))
            default:
                scale
            }
        }
    }
}

// The three fields a twenty-three-byte encoding carries, read out but not yet validated into a currency.
// Shared by the typed and runtime decoders, which differ only in how they turn the code and scale into
// a currency.
@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
@inlinable
func decodedUnroundedFields(_ bytes: InlineArray<23, UInt8>) -> (minorUnits: Fixed, code: CurrencyCode, scale: UnitScale)? {
    var amount: UInt128 = 0
    for index in 0 ... 15 {
        amount = amount << 8 | UInt128(bytes[index])
    }

    var packedCode: UInt64 = 0
    for index in 16 ... 21 {
        packedCode = packedCode << 8 | UInt64(bytes[index])
    }

    guard let code = CurrencyCode(compactValue: packedCode),
          let scale = UnitScale(decimalPlaces: Int(bytes[22])) else {
        return nil
    }

    return (Fixed(storageBits: Int128(bitPattern: amount)), code, scale)
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf.Unrounded where C: CurrencyType {
    /// Rebuilds a typed unrounded amount from its twenty-three-byte encoding.
    ///
    /// - Returns: `nil` unless the bytes are a valid encoding whose currency is the one this type names.
    ///   The code and scale in the bytes must match `C`'s own, so decoding `GBP` bytes as `EUR` fails.
    @inlinable
    init?(bytes: InlineArray<23, UInt8>) {
        guard let fields = decodedUnroundedFields(bytes),
              fields.code == C.currency.code,
              fields.scale == C.currency.unitScale else {
            return nil
        }

        self.init(fields.minorUnits, storage: .implied)
    }
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf.Unrounded where C == AnyCurrency {
    /// Rebuilds a runtime-currency unrounded amount from its twenty-three-byte encoding.
    ///
    /// - Returns: `nil` unless the bytes are a valid encoding: a valid code and scale that name a
    ///   currency, and a scale the code does not contradict (a currency the library ships at a
    ///   different scale is refused).
    @inlinable
    init?(bytes: InlineArray<23, UInt8>) {
        guard let fields = decodedUnroundedFields(bytes),
              let currency = Currency(code: fields.code, unitScale: fields.scale) else {
            return nil
        }

        self.init(fields.minorUnits, storage: currency)
    }
}

@available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
public extension MoneyOf {
    /// This settled amount as the unrounded encoding, without settling anything.
    ///
    /// A ledger that stores every balance in the unrounded form can write a settled amount into it with
    /// this, rather than encoding it as settled bytes and converting later. The amount is widened to the
    /// unrounded form first — a genuine multiply by 10^18, not a zero-pad — so it reads back as
    /// ``Unrounded/init(bytes:)`` expects. Equivalent to `unrounded.bytes`.
    @inlinable
    var unroundedBytes: InlineArray<23, UInt8> {
        unrounded.bytes
    }
}

extension MoneyOf: CustomStringConvertible {
    /// The amount and its currency, written the same way in every locale.
    ///
    /// ```swift
    /// String(describing: GBP(minorUnits: 4_99))   // "GBP 4.99"
    /// String(describing: JPY(minorUnits: 499))    // "JPY 499"
    /// ```
    ///
    /// Always major units, written to the number of places the currency's scale divides into: two
    /// for sterling, none for yen.
    public var description: String {
        codedString(.majorUnits)
    }
}

extension MoneyOf {
    // The code and the amount in one string, which `description` and `Codable` both write.
    //
    // Inlined because both callers pass a literal, which lets the units test fold away entirely.
    // Without this it costs `description` nine instructions.
    @inline(__always)
    func codedString(_ units: MoneyCodingUnits) -> String {
        // Held rather than read twice: reaching it goes through the currency representation.
        let currency = self.currency
        let scale = UInt64(Int64(currency.unitScale))
        let magnitude = minorUnits.magnitude
        let places = units == .majorUnits && scale > 1 ? currency.unitScale.decimalPlaces : 0

        let whole = places == 0 ? magnitude : magnitude / scale
        let fraction = places == 0 ? 0 : magnitude % scale

        let sign = minorUnits < 0 ? 1 : 0
        let point = places == 0 ? 0 : 1 + places
        let length = currency.code.utf8Count + 1 + sign + whole.digitCount + point

        // Sized exactly rather than generously, because a request over fifteen bytes gives up the
        // small-string form and takes a heap allocation with it. Ordinary amounts stay well inside.
        return String(unsafeUninitializedCapacity: length) { buffer in
            var offset = 0

            currency.code.write(into: buffer, at: &offset)
            buffer[offset] = UInt8(ascii: " ")
            offset += 1

            if sign == 1 {
                buffer[offset] = UInt8(ascii: "-")
                offset += 1
            }

            whole.writeDigits(into: buffer, at: &offset, from: UInt64.powerOfTen(.init(leadingDigitOf: whole)))

            if places > 0 {
                buffer[offset] = UInt8(ascii: ".")
                offset += 1
                // `scale` is ten to `places`, so this writes `places` digits.
                fraction.writeDigits(into: buffer, at: &offset, from: scale / 10)
            }

            return offset
        }
    }

    // The amount alone, for a wire form carrying the currency in a field of its own.
    //
    // Trimmed from the coded string rather than written by a second buffer pass. Three attempts at
    // sharing one writer between the two, a flag, a layout struct, and an inlined layout struct,
    // each cost `description` between 9 and 95 instructions, because what they share sits inside the
    // buffer closure where a constant does not reach. This costs one extra allocation on a path that
    // runs inside a coder costing twenty thousand instructions, and leaves `description` untouched.
    func amountText(_ units: MoneyCodingUnits) -> String {
        String(codedString(units).dropFirst(currency.code.utf8Count + 1))
    }
}

private extension UInt64 {
    var digitCount: Int {
        var digits = 1
        var remaining = self

        while remaining >= 10 {
            remaining /= 10
            digits += 1
        }

        return digits
    }

    // Written most significant digit first, from the place `divisor` counts down to the units, so a
    // caller composing a longer string never has to reverse or pad afterwards.
    func writeDigits(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: inout Int,
        from divisor: UInt64
    ) {
        var divisor = divisor
        var remaining = self

        while divisor > 0 {
            buffer[offset] = UInt8(remaining / divisor) &+ UInt8(ascii: "0")
            offset += 1
            remaining %= divisor
            divisor /= 10
        }
    }
}

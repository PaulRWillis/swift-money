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
    func codedString(_ units: MoneyCodingFormat.Units) -> String {
        // Held rather than read twice: reaching it goes through the currency representation.
        let currency = self.currency
        let scale = UInt64(Int64(currency.unitScale))
        let magnitude = minorUnits.magnitude
        let places = units == .majorUnits && scale > 1 ? currency.unitScale.decimalPlaces : 0

        // Dividing before multiplying is what keeps this inside a `UInt64`: the scale divides
        // `10 ^ places` exactly, so the multiplier is whole and the product stays under `10 ^ places`.
        let whole = places == 0 ? magnitude : magnitude / scale
        let fraction = places == 0 ? 0 : magnitude % scale * (UInt64.powerOfTen(places) / scale)

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

            whole.writeDigits(into: buffer, at: &offset, count: whole.digitCount)

            if places > 0 {
                buffer[offset] = UInt8(ascii: ".")
                offset += 1
                fraction.writeDigits(into: buffer, at: &offset, count: places)
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
    func amountText(_ units: MoneyCodingFormat.Units) -> String {
        String(codedString(units).dropFirst(currency.code.utf8Count + 1))
    }
}

extension UInt64 {
    @usableFromInline
    package static func powerOfTen(_ exponent: Int) -> UInt64 {
        (0 ..< exponent).reduce(into: UInt64(1)) { power, _ in power *= 10 }
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

    // Written most significant digit first, zero padded to `count`, so a caller composing a longer
    // string never has to reverse or pad afterwards.
    func writeDigits(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: inout Int,
        count: Int
    ) {
        var divisor = UInt64.powerOfTen(count - 1)
        var remaining = self

        while divisor > 0 {
            buffer[offset] = UInt8(remaining / divisor) &+ UInt8(ascii: "0")
            offset += 1
            remaining %= divisor
            divisor /= 10
        }
    }
}

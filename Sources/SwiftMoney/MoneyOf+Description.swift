extension MoneyOf: CustomStringConvertible {
    /// The amount and its currency, written the same way in every locale.
    ///
    /// ```swift
    /// String(describing: GBP(minorUnits: 4_99))   // "GBP 4.99"
    /// String(describing: JPY(minorUnits: 499))    // "JPY 499"
    /// ```
    ///
    /// Major units wherever the currency's scale divides a power of ten, which every ISO 4217
    /// currency's does. Where it does not, the currency's smallest units, no exact decimal being
    /// available: a pound of 240 pence cannot write seven of them.
    public var description: String {
        // Held rather than read twice: reaching it goes through the currency representation.
        let currency = self.currency
        let scale = UInt64(Int64(currency.unitScale))
        let magnitude = minorUnits.magnitude
        let places = scale > 1 ? scale.exactDecimalPlaces ?? 0 : 0

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
}

private extension UInt64 {
    // Two and five are the only prime factors a decimal can absorb, so a scale keeping any other has
    // no exact decimal at all: 240 keeps a 3, and seven of its subunits is 0.0291666…
    //
    // Beyond eighteen places the digits outgrow a `UInt64`. Only a scale such as `2 ^ 30` reaches
    // that, and it settles for minor units.
    var exactDecimalPlaces: Int? {
        var remaining = self
        var twos = 0
        var fives = 0

        while remaining.isMultiple(of: 2) {
            remaining /= 2
            twos += 1
        }

        while remaining.isMultiple(of: 5) {
            remaining /= 5
            fives += 1
        }

        // `Swift.max`, because `max` inside an extension on `UInt64` is that type's largest value.
        let places = Swift.max(twos, fives)

        return remaining == 1 && places <= 18 ? places : nil
    }

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

    static func powerOfTen(_ exponent: Int) -> UInt64 {
        (0 ..< exponent).reduce(into: UInt64(1)) { power, _ in power *= 10 }
    }
}

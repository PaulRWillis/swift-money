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
        let code = currency.code
        let scale = UInt64(Int64(currency.unitScale))
        let magnitude = minorUnits.magnitude

        guard scale > 1, let places = scale.exactDecimalPlaces else {
            return "\(code) \(minorUnits)"
        }

        // Dividing before multiplying is what keeps this inside a `UInt64`: the scale divides
        // `10 ^ places` exactly, so the multiplier is whole, and the product stays under `10 ^ places`.
        let digits = String(magnitude % scale * (UInt64.powerOfTen(places) / scale))
        let sign = minorUnits < 0 ? "-" : ""

        return "\(code) \(sign)\(magnitude / scale)."
            + String(repeating: "0", count: places - digits.count)
            + digits
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

    static func powerOfTen(_ exponent: Int) -> UInt64 {
        (0 ..< exponent).reduce(into: UInt64(1)) { power, _ in power *= 10 }
    }
}

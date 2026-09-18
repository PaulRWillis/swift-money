import SwiftMoneyCore

/// One value CLDR publishes as a sample for a plural rule, as an amount of a currency.
///
/// The scale is the one that writes the sample's fraction digits exactly, so `1.30` is 130 smallest
/// units of a currency with two of them, and `1` is one unit of a currency with none.
package struct PluralSample: Equatable, Sendable {
    /// The amount, in the currency's smallest units.
    package let minorUnits: Int64

    /// The scale that shows the sample's fraction digits.
    package let unitScale: UnitScale

    package init(minorUnits: Int64, unitScale: UnitScale) {
        self.minorUnits = minorUnits
        self.unitScale = unitScale
    }
}

extension PluralSample: CustomStringConvertible {
    /// The sample written as CLDR writes it, such as `"1.30"`.
    package var description: String {
        guard unitScale.decimalPlaces > 0 else {
            return "\(minorUnits)"
        }

        let scale = Int64(unitScale)
        let fraction = String(minorUnits % scale)
        let leadingZeros = String(repeating: "0", count: unitScale.decimalPlaces - fraction.count)

        return "\(minorUnits / scale).\(leadingZeros)\(fraction)"
    }
}

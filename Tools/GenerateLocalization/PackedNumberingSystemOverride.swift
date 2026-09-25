import SwiftMoneyLocalization

// One locale's separator override for a system that imposes its own: the locale writes the system with
// these separators rather than the system's default. Laid out sorted by (localeIndex, systemIndex) so the
// runtime finds a row by binary search.
struct PackedNumberingSystemOverride {
    let localeIndex: UInt16
    let systemIndex: UInt8
    let decimalSeparator: StringRef
    let groupingSeparator: StringRef
    let minusSign: StringRef
}

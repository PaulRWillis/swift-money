import SwiftMoneyLocalization

// One numbering system's data in the shape the packed table holds it: name and digits already pooled, and
// the separators it imposes (empty refs when it reuses the locale's). Records are laid out sorted by name.
struct PackedNumberingSystem {
    let name: StringRef
    let provenanceTag: UInt8
    let digits: StringRef
    let decimalSeparator: StringRef
    let groupingSeparator: StringRef
    let minusSign: StringRef
}

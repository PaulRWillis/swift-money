package extension SymbolForm {
    /// This form's bit in the packed tables. Explicit rather than the enum's declaration order, so the
    /// encoding cannot shift if that order ever changes.
    var blobBit: UInt8 {
        switch self {
        case .glyph: 0
        case .letters: 1
        }
    }

    /// The form a packed bit stands for, or `nil` if neither.
    init?(blobBit: UInt8) {
        switch blobBit {
        case 0: self = .glyph
        case 1: self = .letters
        default: return nil
        }
    }
}

package extension PluralCategory {
    /// This category's byte in the packed tables. Explicit rather than the enum's declaration order, so
    /// the encoding cannot shift if that order ever changes.
    var blobCode: UInt8 {
        switch self {
        case .zero: 0
        case .one: 1
        case .two: 2
        case .few: 3
        case .many: 4
        case .other: 5
        }
    }

    /// The category a packed byte stands for, or `nil` if none.
    init?(blobCode: UInt8) {
        switch blobCode {
        case 0: self = .zero
        case 1: self = .one
        case 2: self = .two
        case 3: self = .few
        case 4: self = .many
        case 5: self = .other
        default: return nil
        }
    }
}

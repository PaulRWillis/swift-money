package extension Spacing {
    /// This gap's byte in the packed tables. Explicit rather than the enum's declaration order, so the
    /// encoding cannot shift if that order ever changes.
    var blobCode: UInt8 {
        switch self {
        case .none: 0
        case .asciiSpace: 1
        case .nonBreakingSpace: 2
        case .narrowNonBreakingSpace: 3
        }
    }

    /// The gap a packed byte stands for, or `nil` if none.
    init?(blobCode: UInt8) {
        switch blobCode {
        case 0: self = .none
        case 1: self = .asciiSpace
        case 2: self = .nonBreakingSpace
        case 3: self = .narrowNonBreakingSpace
        default: return nil
        }
    }
}

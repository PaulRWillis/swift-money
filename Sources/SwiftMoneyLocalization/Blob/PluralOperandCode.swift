package extension PluralOperand {
    /// This operand's byte in the packed tables. Explicit rather than the enum's declaration order, so
    /// the encoding cannot shift if that order ever changes.
    var blobCode: UInt8 {
        switch self {
        case .absoluteValue: 0
        case .integerPart: 1
        case .fractionDigitCount: 2
        case .significantFractionDigitCount: 3
        case .fractionDigits: 4
        case .significantFractionDigits: 5
        case .compactExponent: 6
        }
    }

    /// The operand a packed byte stands for, or `nil` if none.
    init?(blobCode: UInt8) {
        switch blobCode {
        case 0: self = .absoluteValue
        case 1: self = .integerPart
        case 2: self = .fractionDigitCount
        case 3: self = .significantFractionDigitCount
        case 4: self = .fractionDigits
        case 5: self = .significantFractionDigits
        case 6: self = .compactExponent
        default: return nil
        }
    }
}

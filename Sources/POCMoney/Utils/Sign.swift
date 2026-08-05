// Which side of zero a value falls on.
//
// Kept apart from magnitude so that arithmetic never has to negate. The smallest value of a signed
// type has no positive counterpart, so taking an absolute value would overflow, while every magnitude
// is an ordinary unsigned integer.
enum Sign: Equatable {
    case positive
    case negative

    init(of value: Int) {
        self = value < 0 ? .negative : .positive
    }

    init(of value: Int64) {
        self = value < 0 ? .negative : .positive
    }

    // A product is negative when exactly one of its operands is.
    static func * (
        lhs: Sign,
        rhs: Sign
    ) -> Sign {
        lhs == rhs ? .positive : .negative
    }
}

extension Int {
    // Rebuilds a signed value from its magnitude. `nil` when the magnitude is too large for this
    // platform's `Int`, which is narrower than an `Int64` on arm64_32.
    init?(
        magnitude: UInt64,
        sign: Sign
    ) {
        // The smallest `Int` is taken from its magnitude directly rather than by negating, having no
        // positive counterpart.
        if sign == .negative, magnitude == UInt64(Int.min.magnitude) {
            self = .min
            return
        }

        guard let positive = Int(exactly: magnitude) else {
            return nil
        }

        self = sign == .negative ? -positive : positive
    }
}

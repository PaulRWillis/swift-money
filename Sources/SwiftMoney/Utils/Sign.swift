// Which side of zero a value falls on.
//
// Kept apart from magnitude so that arithmetic never has to negate. The smallest value of a signed
// type has no positive counterpart, so taking an absolute value would overflow, while every magnitude
// is an ordinary unsigned integer.
package enum Sign: Equatable {
    case positive
    case negative

    // Zero counts as positive. It has no sign of its own, but nothing here needs one: a zero magnitude
    // is the same value whichever sign is applied to it.
    package init(of value: some SignedInteger) {
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

extension Int64 {
    // Rebuilds a signed value from its magnitude. `nil` when the magnitude has no signed counterpart.
    init?(
        magnitude: UInt64,
        sign: Sign
    ) {
        // The smallest `Int64` is taken from its magnitude directly rather than by negating, having no
        // positive counterpart.
        if sign == .negative, magnitude == Int64.min.magnitude {
            self = .min
            return
        }

        guard let positive = Int64(exactly: magnitude) else {
            return nil
        }

        self = sign == .negative ? -positive : positive
    }
}

extension Int128 {
    // Rebuilds a signed value from its magnitude. `nil` when the magnitude has no signed counterpart.
    package init?(
        magnitude: UInt128,
        sign: Sign
    ) {
        // The smallest `Int128` is taken from its magnitude directly rather than by negating, having no
        // positive counterpart.
        if sign == .negative, magnitude == Int128.min.magnitude {
            self = .min
            return
        }

        guard let positive = Int128(exactly: magnitude) else {
            return nil
        }

        self = sign == .negative ? -positive : positive
    }
}

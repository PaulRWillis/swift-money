// Whether a whole number is even or odd: how half-to-even breaks a tie.
enum Parity {
    case even
    case odd

    init(of value: some BinaryInteger) {
        self = value.isMultiple(of: 2) ? .even : .odd
    }
}

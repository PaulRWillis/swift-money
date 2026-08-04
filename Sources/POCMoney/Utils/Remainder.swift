enum Remainder {
    case zero
    case nonZero(NonZeroInt)

    init(_ value: Int) {
        if let nonZero = NonZeroInt(value) {
            self = .nonZero(nonZero)
        } else {
            self = .zero
        }
    }
}

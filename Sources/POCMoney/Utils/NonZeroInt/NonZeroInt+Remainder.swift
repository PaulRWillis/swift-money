extension NonZeroInt {
    // What a division left over. Nested so that the enclosing type answers "a remainder of what",
    // which matters once more than one kind of remainder exists.
    enum Remainder {
        case zero
        case nonZero(NonZeroInt)

        init(_ value: Int64) {
            if let nonZero = NonZeroInt(value) {
                self = .nonZero(nonZero)
            } else {
                self = .zero
            }
        }
    }
}

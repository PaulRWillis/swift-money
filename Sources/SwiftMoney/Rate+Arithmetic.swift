extension Rate {
    // A 1:1 rate. Internal: the FX types use it to express "the mid rate less a margin" as
    // `rate × (par − margin)`.
    static let par = Rate(Fixed(1))

    // This rate multiplied by another, or `nil` if the product is out of range. Internal: exchange
    // rates compose through it (`crossed(with:)`), and a margin is applied through it.
    func multiplied(by other: Rate) -> Rate? {
        value.multipliedIfRepresentable(by: other.value).map(Rate.init)
    }

    // This rate subtracted from another. Internal: `par − margin` gives the fraction of the mid rate a
    // customer keeps. Both operands are in `[0, 1]` here, so the difference is representable.
    func subtracted(from other: Rate) -> Rate {
        Rate(other.value - value)
    }

    // Whether this rate is strictly greater than zero. Internal: an exchange rate must be positive.
    var isPositive: Bool {
        value > .zero
    }

    // Whether this rate is at least zero and less than one. Internal: a margin must sit in `[0, 1)`.
    var isFractionOfWhole: Bool {
        value >= .zero && value < Rate.par.value
    }
}

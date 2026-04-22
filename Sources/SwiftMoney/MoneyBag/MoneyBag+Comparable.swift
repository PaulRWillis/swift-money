extension MoneyBag: Equatable {
    /// Two `MoneyBag` values are equal when they contain the same set of
    /// currency codes, each with identical accumulated minor units.
    ///
    /// Equality is independent of the order in which values were added. A bag
    /// that contains a zero entry for a given currency is **not** equal to an
    /// empty bag — the zero entry is structurally present.
    public static func == (lhs: MoneyBag, rhs: MoneyBag) -> Bool {
        lhs._storage == rhs._storage
    }
}

extension MoneyBag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_storage)
    }
}

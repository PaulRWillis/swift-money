extension MoneyBag {

    /// Converts all accumulated amounts to a single currency and returns their sum.
    ///
    /// Each currency in the bag is converted to `Target` via
    /// `provider.rate(from:to:)`. Amounts already in `Target` are passed
    /// through the provider as well, so implementors should return an identity
    /// rate `ExchangeRate(from: 1, to: 1)!` for same-currency pairs rather
    /// than `nil`.
    ///
    /// ```swift
    /// // £5.00 + €10.00, converting EUR→GBP at 85p per €1
    /// var bag = MoneyBag()
    /// bag.add(Money<GBP>(minorUnits: 500))
    /// bag.add(Money<EUR>(minorUnits: 1000))
    ///
    /// let total = bag.total(in: GBP.self, using: myProvider)
    /// // total == Money<GBP>(minorUnits: 1350)  (500 + 850)
    /// ```
    ///
    /// Returns `nil` when:
    /// - Any entry's currency metatype is `nil` (the bag entry was decoded from
    ///   `Codable` and the concrete type is not known at runtime).
    /// - The provider returns `nil` for any currency pair.
    ///
    /// Returns `Money<Target>.zero` when the bag is empty.
    ///
    /// - Parameters:
    ///   - target:   The target currency to convert everything into.
    ///   - provider: An ``ExchangeRateProvider`` supplying conversion rates.
    ///   - rounding: The rounding rule for fractional minor units.
    ///     Defaults to `.toNearestOrAwayFromZero`.
    /// - Returns: The total converted amount, or `nil` if conversion is
    ///   impossible.
    public func total<Target: Currency>(
        in target: Target.Type,
        using provider: some ExchangeRateProvider,
        rounding: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) -> Money<Target>? {
        guard !isEmpty else { return .zero }

        var accumulator = Money<Target>.zero

        for anyMoney in _storage.values {
            guard let fromType = anyMoney.currency else { return nil }

            // Local generic function so SE-0352 opens the metatype existential
            // `fromType` at the call site below, binding `From` to the concrete type.
            func convert<From: Currency>(_ from: From.Type) -> Money<Target>? {
                guard let rate = provider.rate(from: from, to: target) else { return nil }
                let source = Money<From>(_unchecked: anyMoney.minorUnits)
                return rate.convert(source, rounding: rounding)
            }

            guard let converted = convert(fromType) else { return nil }
            accumulator = accumulator + converted
        }

        return accumulator
    }
}

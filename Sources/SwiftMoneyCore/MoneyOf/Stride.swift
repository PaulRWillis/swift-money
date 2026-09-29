public extension MoneyOf {
    /// A non-zero amount to step by.
    ///
    /// A negative stride steps downward, as the standard library's do. A stride of zero would never
    /// reach its end, so it cannot be constructed:
    ///
    /// ```swift
    /// GBP.Stride.majorUnit                 // £1
    /// GBP.Stride.minorUnits(50)            // 50p
    /// Money.Stride.majorUnit(of: amount)   // one major unit in `amount`'s currency
    /// Money.Stride(exactly: serverStep)    // nil when the step is zero
    /// ```
    struct Stride: Equatable, Hashable, Sendable {
        /// The amount each step moves by, never zero.
        public let amount: MoneyOf<C>

        /// Creates a stride from an amount that may be zero.
        ///
        /// Use this for a step from outside the program, where zero is bad input rather than a
        /// mistake in the source.
        ///
        /// - Parameter amount: The amount to step by. Negative steps downward.
        /// - Returns: `nil` if `amount` is zero.
        @inlinable
        public init?(exactly amount: MoneyOf<C>) {
            guard amount.minorUnits != 0 else {
                return nil
            }

            self.init(unchecked: amount)
        }

        // No check: for call sites that already know the amount is not zero.
        @usableFromInline
        init(unchecked amount: MoneyOf<C>) {
            self.amount = amount
        }
    }
}

public extension MoneyOf.Stride where C: CurrencyType {
    /// A stride of one minor unit: 1p for pounds, ¥1 for yen.
    @inlinable
    static var minorUnit: Self {
        Self(unchecked: MoneyOf(unchecked: 1, storage: .implied))
    }

    /// A stride of one major unit: £1 for pounds, ¥1 for yen.
    ///
    /// The currency's scale is read for you, so a stride of a pound is never mistaken for a stride of
    /// a hundred yen.
    @inlinable
    static var majorUnit: Self {
        Self(unchecked: MoneyOf(unchecked: Int64(C.currency.unitScale), storage: .implied))
    }

    /// Returns a stride of a whole number of minor units.
    ///
    /// ```swift
    /// GBP.Stride.minorUnits(50)    // 50p
    /// ```
    ///
    /// - Parameter count: The number of minor units, a non-zero literal. Negative steps downward.
    @inlinable
    static func minorUnits(_ count: UnitCount) -> Self {
        Self(unchecked: MoneyOf(unchecked: count.count, storage: .implied))
    }

    /// Returns a stride of a whole number of major units.
    ///
    /// ```swift
    /// GBP.Stride.majorUnits(5)    // £5
    /// JPY.Stride.majorUnits(5)    // ¥5
    /// ```
    ///
    /// - Parameter count: The number of major units, a non-zero literal. Negative steps downward.
    /// - Precondition: `count` major units fit an amount in this currency. Only a literal can be a
    ///   count, so a count too large is a mistake in the source.
    @inlinable
    static func majorUnits(_ count: UnitCount) -> Self {
        Self(unchecked: MoneyOf(unchecked: count.minorUnits(asMajorUnitsOf: C.currency), storage: .implied))
    }

    /// Creates a typed stride from a runtime one, if it is in this type's currency.
    ///
    /// - Parameter stride: The stride whose currency is only known at runtime.
    /// - Throws: ``MoneyError/currencyMismatch(lhs:rhs:)`` if `stride` is in another currency, with
    ///   this type's currency as `lhs`.
    @inlinable
    init(_ stride: Money.Stride) throws(MoneyError) {
        self.init(unchecked: try MoneyOf(stride.amount))
    }
}

public extension MoneyOf.Stride where C == AnyCurrency {
    /// Creates a runtime stride from a typed one, keeping its amount and currency.
    ///
    /// - Parameter typed: The stride whose currency is fixed by its type.
    @inlinable
    init<T: CurrencyType>(_ typed: MoneyOf<T>.Stride) {
        self.init(unchecked: Money(typed.amount))
    }

    /// Returns a stride of one minor unit of a currency.
    ///
    /// - Parameter currency: The currency to step in.
    @inlinable
    static func minorUnit(of currency: Currency) -> Self {
        Self(unchecked: Money(unchecked: 1, storage: currency))
    }

    /// Returns a stride of one major unit of a currency: its scale in minor units.
    ///
    /// ```swift
    /// Money.Stride.majorUnit(of: .gbp)    // £1
    /// Money.Stride.majorUnit(of: .jpy)    // ¥1, not ¥100
    /// ```
    ///
    /// - Parameter currency: The currency to step in.
    @inlinable
    static func majorUnit(of currency: Currency) -> Self {
        Self(unchecked: Money(unchecked: Int64(currency.unitScale), storage: currency))
    }

    /// Returns a stride of one minor unit, in an amount's currency.
    ///
    /// ```swift
    /// let step = Money.Stride.minorUnit(of: balance)
    /// ```
    ///
    /// - Parameter amount: An amount in the currency to step in.
    @inlinable
    static func minorUnit(of amount: Money) -> Self {
        minorUnit(of: amount.storage)
    }

    /// Returns a stride of one major unit, in an amount's currency.
    ///
    /// - Parameter amount: An amount in the currency to step in.
    @inlinable
    static func majorUnit(of amount: Money) -> Self {
        majorUnit(of: amount.storage)
    }

    /// Returns a stride of a whole number of a currency's minor units.
    ///
    /// ```swift
    /// Money.Stride.minorUnits(50, of: .gbp)    // 50p
    /// ```
    ///
    /// - Parameters:
    ///   - count: The number of minor units, a non-zero literal. Negative steps downward.
    ///   - currency: The currency to step in.
    @inlinable
    static func minorUnits(
        _ count: UnitCount,
        of currency: Currency
    ) -> Self {
        Self(unchecked: Money(unchecked: count.count, storage: currency))
    }

    /// Returns a stride of a whole number of a currency's major units, if that many fit an amount.
    ///
    /// ```swift
    /// Money.Stride.majorUnits(5, of: .gbp)    // £5
    /// ```
    ///
    /// The currency is only known at runtime, so a count too large for its scale is bad input rather
    /// than a mistake in the source, as it is for `Money(majorUnits:currency:)`.
    ///
    /// - Parameters:
    ///   - count: The number of major units, a non-zero literal. Negative steps downward.
    ///   - currency: The currency to step in.
    /// - Returns: `nil` if `count` major units are too large to hold once scaled to minor units.
    @inlinable
    static func majorUnits(
        _ count: UnitCount,
        of currency: Currency
    ) -> Self? {
        guard let minorUnits = scaledToMinorUnits(count.count, in: currency) else {
            return nil
        }

        return Self(unchecked: Money(unchecked: minorUnits, storage: currency))
    }

    /// Returns a stride of a whole number of minor units, in an amount's currency.
    ///
    /// - Parameters:
    ///   - count: The number of minor units, a non-zero literal. Negative steps downward.
    ///   - amount: An amount in the currency to step in.
    @inlinable
    static func minorUnits(
        _ count: UnitCount,
        of amount: Money
    ) -> Self {
        minorUnits(count, of: amount.storage)
    }

    /// Returns a stride of a whole number of major units in an amount's currency, if that many fit an
    /// amount.
    ///
    /// - Parameters:
    ///   - count: The number of major units, a non-zero literal. Negative steps downward.
    ///   - amount: An amount in the currency to step in.
    /// - Returns: `nil` if `count` major units are too large to hold once scaled to minor units.
    @inlinable
    static func majorUnits(
        _ count: UnitCount,
        of amount: Money
    ) -> Self? {
        majorUnits(count, of: amount.storage)
    }
}

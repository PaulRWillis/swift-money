/// A monetary amount.
///
/// The currency comes from the generic parameter, which decides both how the amount knows its
/// currency and whether combining two amounts can fail.
///
/// With a currency fixed at compile time, adding pounds to euros is a compile error and arithmetic
/// needs no `try`:
///
/// ```swift
/// let total = GBP(minorUnits: 4_99) + GBP(minorUnits: 1_00)
/// ```
///
/// With ``Money``, where the currency is only known at runtime, the same mistake cannot be caught
/// until it happens, so arithmetic throws instead. One `try` covers a whole expression:
///
/// ```swift
/// let total = try (price * 3) + delivery - discount
/// ```
public struct MoneyOf<C: CurrencyRepresentation>: Equatable, Hashable, Sendable {
    @usableFromInline
    let minorUnits: Int64

    @usableFromInline
    let storage: C.Storage

    /// The currency this amount is denominated in.
    @inlinable
    public var currency: Currency {
        C.currency(for: storage)
    }

    // No range check: for call sites holding a value this type computed, and so already knows is
    // representable. Public construction validates; internal arithmetic must not pay for it.
    @usableFromInline
    @inlinable
    init(
        unchecked minorUnits: Int64,
        storage: C.Storage
    ) {
        self.minorUnits = minorUnits
        self.storage = storage
    }
}

// MARK: - Construction

public extension MoneyOf where C: CurrencyType {
    /// Creates a monetary amount from a whole number of the currency's smallest
    /// (minor) units.
    ///
    /// ```swift
    /// let gbp = GBP(minorUnits: 4_99)   // £4.99
    /// let jpy = JPY(minorUnits: 4_99)   // ¥499
    /// ```
    ///
    /// Takes any integer type, so the width an amount is stored in stays out of this signature and
    /// can change without breaking callers.
    ///
    /// - Parameter minorUnits: The number of the currency's smallest units.
    /// - Precondition: `minorUnits` is representable. A value beyond ``min`` or ``max`` traps, as
    ///   arithmetic that leaves the range does.
    @inlinable
    init(minorUnits: some BinaryInteger) {
        guard let representable = Int64(exactly: minorUnits) else {
            preconditionFailure("Not a representable amount: \(minorUnits)")
        }

        self.init(unchecked: representable, storage: .implied)
    }

    /// Creates a monetary amount from a whole number of the currency's smallest (minor) units, if
    /// the count is representable.
    ///
    /// Use this for a value from outside the program, where an amount too large to hold is bad input
    /// rather than a mistake in the source. The range an amount can hold is deliberately not part of
    /// this API, so a caller cannot check it beforehand.
    ///
    /// - Parameter minorUnits: The number of the currency's smallest units.
    /// - Returns: `nil` if `minorUnits` is outside the range an amount can hold.
    @inlinable
    init?(exactly minorUnits: some BinaryInteger) {
        guard let representable = Int64(exactly: minorUnits) else {
            return nil
        }

        self.init(unchecked: representable, storage: .implied)
    }
}

public extension MoneyOf where C == AnyCurrency {
    /// Creates a monetary amount from a whole number of the currency's smallest
    /// (minor) units.
    ///
    /// ```swift
    /// let price = Money(minorUnits: 4_99, currency: .gbp)   // £4.99
    /// ```
    ///
    /// - Parameters:
    ///   - minorUnits: The number of the currency's smallest units.
    ///   - currency: The currency to denominate the amount in. Two amounts combine only when their
    ///     currencies are equal, and that includes the quantization: `XYZ` at 100 and `XYZ` at 1 are
    ///     different currencies.
    /// - Precondition: `minorUnits` is representable.
    @inlinable
    init(
        minorUnits: some BinaryInteger,
        currency: Currency
    ) {
        guard let representable = Int64(exactly: minorUnits) else {
            preconditionFailure("Not a representable amount: \(minorUnits)")
        }

        self.init(unchecked: representable, storage: currency)
    }

    /// Creates a monetary amount from a whole number of the currency's smallest (minor) units, if
    /// the count is representable.
    ///
    /// - Parameters:
    ///   - minorUnits: The number of the currency's smallest units.
    ///   - currency: The currency to denominate the amount in.
    /// - Returns: `nil` if `minorUnits` is outside the range an amount can hold.
    @inlinable
    init?(
        exactly minorUnits: some BinaryInteger,
        currency: Currency
    ) {
        guard let representable = Int64(exactly: minorUnits) else {
            return nil
        }

        self.init(unchecked: representable, storage: currency)
    }
}

// MARK: - Min/Max

public extension MoneyOf where C: CurrencyType {
    /// The smallest representable monetary amount.
    static var min: Self {
        Self(unchecked: Int64.min, storage: .implied)
    }

    /// The largest representable monetary amount.
    static var max: Self {
        Self(unchecked: Int64.max, storage: .implied)
    }
}

// MARK: - Integer Conversions

extension Int {
    /// Creates an `Int` from a `Money`.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// Int(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the integer part of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(exactly: pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(exactly: yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to Int")
        self = Int(value.minorUnits)
    }

    /// Creates an `Int` from a `Money`, returning `nil` if the
    /// value is NaN.
    ///
    /// ```swift
    /// Int(exactly: Money<GBP>(minorUnits: 42))   // Optional(42)
    /// Int(exactly: Money<GBP>.nan)    // nil
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the integer part of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(exactly: pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(exactly: yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        if value.isNaN { return nil }
        self = Int(value.minorUnits)
    }
}

extension Int64 {
    /// Creates an `Int64` from a `Money`.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: -79) // -79p or -£0.79
    /// Int64(v)  // -79
    /// ```
    ///
    /// The `Int64` value represents the number of minor units in the money
    /// type, not the integer part of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int64(exactly: pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int64(exactly: yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to Int64")
        self = value.minorUnits
    }

    /// Creates an `Int64` from a `Money`, returning `nil` if the
    /// value is NaN or exceeds `Int64` range.
    ///
    /// ```swift
    /// Int(exactly: Money<GBP>(minorUnits: 42))   // Optional(42)
    /// Int(exactly: Money<GBP>.nan)    // nil
    /// ```
    ///
    /// The `Int64` value represents the number of minor units in the money
    /// type, not the integer part of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int64(exactly: pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int64(exactly: yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int64` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        if value.isNaN { return nil }
        self = value.minorUnits
    }
}

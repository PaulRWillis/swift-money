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
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to Int")
        guard let narrow = Int(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int range")
        }
        self = narrow
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
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        if value.isNaN { return nil }
        guard let narrow = Int(exactly: value.minorUnits) else { return nil }
        self = narrow
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
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int64(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int64(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to Int64")
        guard let narrow = Int64(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int64 range")
        }
        self = narrow
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
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int64(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int64(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int64` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        if value.isNaN { return nil }
        guard let narrow = Int64(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

extension Int32 {
    /// Creates an `Int32` from a `Money`.
    /// Traps if the integer part exceeds `Int32` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// Int32(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The integer part must fit in `Int32`.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to Int32")
        guard let narrow = Int32(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds Int32 range")
        }
        self = narrow
    }

    /// Creates an `Int32` from a `Money`, returning `nil` if the
    /// value is NaN or exceeds `Int32` range.
    ///
    /// ```swift
    /// Int32(exactly: Money<GBP>(minorUnits: 42))   // Optional(42)
    /// Int32(exactly: Money<GBP>.nan)    // nil
    /// ```
    ///
    /// The `Int32` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// Int32(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// Int32(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: An `Int32` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        if value.isNaN { return nil }
        guard let narrow = Int32(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

// MARK: - Unsigned Integer Conversions

extension UInt {
    /// Creates a `UInt` from a `Money`.
    /// Traps if the integer part exceeds `UInt` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// UInt(v)  // 42
    /// ```
    ///
    /// The `UInt` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The integer part must fit in `UInt`.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to UInt")
        guard let narrow = UInt(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds UInt range")
        }
        self = narrow
    }

    /// Creates a `UInt` from a `Money`, returning `nil` if the
    /// value is NaN or exceeds `UInt` range.
    ///
    /// ```swift
    /// UInt(exactly: Money<GBP>(minorUnits: 42)    // Optional(42)
    /// UInt(exactly: Money<GBP>.nan)   // nil
    /// ```
    ///
    /// The `UInt` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: A `UInt` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        guard !value.isNaN else { return nil }
        guard let narrow = UInt(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

extension UInt64 {
    /// Creates a `UInt64` from a `Money`.
    /// Traps if the integer part exceeds `UInt64` range.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// UInt64(v)  // 42
    /// ```
    ///
    /// The `Int` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt64(pounds) // 153
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt64(yen) // 153
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The integer part must fit in `UInt64`.
    @inlinable
    public init<C: Currency>(_ value: Money<C>) {
        precondition(!value.isNaN, "Cannot convert NaN to UInt64")
        guard let narrow = UInt64(exactly: value.minorUnits) else {
            preconditionFailure("Money minor units, \(value.minorUnits), exceeds UInt64 range")
        }
        self = narrow
    }

    /// Creates a `UInt64` from a `Money`, returning `nil` if the
    /// value is NaN or exceeds`UInt64` range.
    ///
    /// ```swift
    /// UInt64(exactly: Money<GBP>(minorUnits: 42)    // Optional(42)
    /// UInt64(exactly: Money<GBP>.nan)   // nil
    /// ```
    ///
    /// The `UInt64` value represents the number of minor units in the money
    /// type, not the major unit of the money value.
    ///
    /// ```swift
    /// let pounds = Money<GBP>(minorUnits: 153) // 153p or £1.53
    /// UInt64(exactly: pounds) // Optional(153)
    ///
    /// let yen = Money<JPY>(minorUnits: 153) // ¥153
    /// UInt64(exactly: yen) // Optional(153)
    /// ```
    ///
    /// - Parameter value: The money value to convert.
    /// - Returns: A `UInt64` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?<C: Currency>(exactly value: Money<C>) {
        guard !value.isNaN else { return nil }
        guard let narrow = UInt64(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

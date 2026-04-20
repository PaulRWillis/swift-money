// MARK: - Integer Conversions

extension Int {
    /// Creates an `Int` from a `Money`.
    ///
    /// ```swift
    /// let v = Money<GBP>(minorUnits: 42) // 42p or £0.42
    /// Int(v)  // 42
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init(_ value: AnyMoney) {
        precondition(!value.isNaN, "Cannot convert NaN to Int")
        self = Int(value.minorUnits)
    }

    /// Creates an `Int` from a `FixedPointDecimal`, returning `nil` if the
    /// value is NaN or has a non-zero fractional part.
    ///
    /// ```swift
    /// Int(exactly: FixedPointDecimal("42.0")!)   // Optional(42)
    /// Int(exactly: FixedPointDecimal("42.5")!)   // nil
    /// Int(exactly: FixedPointDecimal.nan)         // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: An `Int` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: AnyMoney) {
        if value.isNaN { return nil }
        self = Int(value.minorUnits)
    }
}

extension Int64 {
    /// Creates an `Int64` from a `FixedPointDecimal`, truncating the fractional part.
    ///
    /// The fractional part is discarded (truncated toward zero).
    ///
    /// ```swift
    /// let v = FixedPointDecimal("-7.9")!
    /// Int64(v)  // -7
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Precondition: The value must not be NaN.
    @inlinable
    public init(_ value: AnyMoney) {
        precondition(!value.isNaN, "Cannot convert NaN to Int64")
        self = value.minorUnits
    }

    /// Creates an `Int64` from a `FixedPointDecimal`, returning `nil` if the
    /// value is NaN or has a non-zero fractional part.
    ///
    /// ```swift
    /// Int64(exactly: FixedPointDecimal("42.0")!)   // Optional(42)
    /// Int64(exactly: FixedPointDecimal("42.5")!)   // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: An `Int64` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: AnyMoney) {
        if value.isNaN { return nil }
        self = value.minorUnits
    }
}

extension Int32 {
    /// Creates an `Int32` from a `FixedPointDecimal`, truncating the fractional part.
    ///
    /// The fractional part is discarded (truncated toward zero).
    /// Traps if the integer part exceeds `Int32` range.
    ///
    /// ```swift
    /// let v = FixedPointDecimal("42.99")!
    /// Int32(v)  // 42
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Precondition: The value must not be NaN.
    /// - Precondition: The integer part must fit in `Int32`.
    @inlinable
    public init(_ value: AnyMoney) {
        precondition(!value.isNaN, "Cannot convert NaN to Int32")
        let minorUnits = value.minorUnits
        precondition(minorUnits >= Int64(Int32.min) && minorUnits <= Int64(Int32.max),
                     "FixedPointDecimal integer part \(minorUnits) exceeds Int32 range")
        self = Int32(minorUnits)
    }

    /// Creates an `Int32` from a `FixedPointDecimal`, returning `nil` if the
    /// value is NaN, has a non-zero fractional part, or exceeds `Int32` range.
    ///
    /// ```swift
    /// Int32(exactly: FixedPointDecimal("42.0")!)   // Optional(42)
    /// Int32(exactly: FixedPointDecimal("42.5")!)   // nil
    /// ```
    ///
    /// - Parameter value: The fixed-point value to convert.
    /// - Returns: An `Int32` if the conversion is exact, otherwise `nil`.
    @inlinable
    public init?(exactly value: AnyMoney) {
        if value.isNaN { return nil }
        guard let narrow = Int32(exactly: value.minorUnits) else { return nil }
        self = narrow
    }
}

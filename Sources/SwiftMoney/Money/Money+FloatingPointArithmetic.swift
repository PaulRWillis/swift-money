// MARK: - Unavailable floating-point multiplication operators
//
// Money is not a number. Multiplying a Money value by a floating-point scalar
// is meaningless and dangerous — it destroys the integer-precision guarantee
// on which all monetary arithmetic in this library depends.
//
// Use `multiplied(by:rounding:)` with a `FractionalRate` for fractional scaling,
// or `*` with an `Int`/`Int64` scalar for integral scaling.
//
// These overloads exist solely to produce a clear compile-time diagnostic;
// they are never callable at runtime.

extension Money {

    @available(*, unavailable, message: "Multiplying Money by Double loses precision. Use multiplied(by:rounding:) with a FractionalRate, or * with an integer scalar.")
    public static func * (lhs: Money, rhs: Double) -> Money { fatalError() }

    @available(*, unavailable, message: "Multiplying Money by Double loses precision. Use multiplied(by:rounding:) with a FractionalRate, or * with an integer scalar.")
    public static func * (lhs: Double, rhs: Money) -> Money { fatalError() }

    @available(*, unavailable, message: "Multiplying Money by Float loses precision. Use multiplied(by:rounding:) with a FractionalRate, or * with an integer scalar.")
    public static func * (lhs: Money, rhs: Float) -> Money { fatalError() }

    @available(*, unavailable, message: "Multiplying Money by Float loses precision. Use multiplied(by:rounding:) with a FractionalRate, or * with an integer scalar.")
    public static func * (lhs: Float, rhs: Money) -> Money { fatalError() }
}

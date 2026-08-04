// A monetary amount: a quantity denominated in a currency.
//
// Internal, and deliberately so. Its job is to stop `Money` and `MoneyOf` drifting apart.
//
// `ArithmeticError` is the variation point: a conformer whose arithmetic cannot fail uses `Never`,
// which makes its operators non-throwing at every call site, while one that can fail names its error.
// A plain non-throwing operator satisfies a `throws(Never)` requirement, so `Never` costs a conformer
// nothing.
protocol MonetaryAmount: Hashable, Sendable {
    associatedtype ArithmeticError: Error

    var currency: Currency { get }

    func split(into parts: PartCount) -> Split<Self>

    static func * (lhs: Self, rhs: Int) throws(ArithmeticError) -> Self
    static func * (lhs: Int, rhs: Self) throws(ArithmeticError) -> Self
    static func *= (lhs: inout Self, rhs: Int) throws(ArithmeticError)
}

// Both conformances are declared here rather than beside their types: the point of the protocol is
// that the two agree, which is only readable when they sit together.
extension MoneyOf: MonetaryAmount {
    typealias ArithmeticError = Never
}

extension Money: MonetaryAmount {
    typealias ArithmeticError = MoneyError
}

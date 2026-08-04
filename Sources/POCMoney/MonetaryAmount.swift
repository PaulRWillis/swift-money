// A monetary amount: a quantity denominated in a currency.
//
// Internal, and deliberately so. Its job is to stop `Money` and `MoneyOf` drifting apart.
protocol MonetaryAmount: Hashable, Sendable {
    var currency: Currency { get }

    func split(into parts: PartCount) -> Split<Self>

    static func * (lhs: Self, rhs: Int) -> Self
    static func * (lhs: Int, rhs: Self) -> Self
    static func *= (lhs: inout Self, rhs: Int)
}

// Both conformances are declared here rather than beside their types: the point of the protocol is
// that the two agree, which is only readable when they sit together.
extension MoneyOf: MonetaryAmount {}
extension Money: MonetaryAmount {}

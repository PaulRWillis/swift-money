import SwiftMoney
import Testing

@Suite("Banker's Divide Tests")
struct BankersDivideTests {

    @Test("An exact half with an even quotient rounds down")
    func exactHalfEvenRoundsDown() {
        // 5 / 2 = 2 remainder 1 (exactly half); 2 is even, so it stays.
        #expect(bankersDivide256(Wide256Magnitude(1, times: 5), by: 2, sign: .positive) == 2)
    }

    @Test("An exact half with an odd quotient rounds up")
    func exactHalfOddRoundsUp() {
        // 7 / 2 = 3 remainder 1 (exactly half); 3 is odd, so it rounds to the even 4.
        #expect(bankersDivide256(Wide256Magnitude(1, times: 7), by: 2, sign: .positive) == 4)
    }

    @Test("Below half truncates")
    func belowHalfTruncates() {
        // 7 / 3 = 2 remainder 1, below half.
        #expect(bankersDivide256(Wide256Magnitude(1, times: 7), by: 3, sign: .positive) == 2)
    }

    @Test("Above half rounds up")
    func aboveHalfRoundsUp() {
        // 8 / 3 = 2 remainder 2, above half.
        #expect(bankersDivide256(Wide256Magnitude(1, times: 8), by: 3, sign: .positive) == 3)
    }

    @Test("A zero remainder is unchanged")
    func zeroRemainder() {
        // 6 / 3 = 2 exactly.
        #expect(bankersDivide256(Wide256Magnitude(1, times: 6), by: 3, sign: .positive) == 2)
    }

    @Test("The sign is applied to the result")
    func signApplied() {
        #expect(bankersDivide256(Wide256Magnitude(1, times: 7), by: 2, sign: .negative) == -4)
    }

    @Test("A quotient at the maximum is returned without overflow")
    func maximumQuotient() {
        let magnitude = UInt128(Int128.max)

        #expect(bankersDivide256(Wide256Magnitude(magnitude, times: 1), by: 1, sign: .positive) == Int128.max)
    }

    @Test("The smallest Int128 is produced from its magnitude")
    func minimumQuotient() {
        let magnitude = Int128.min.magnitude

        #expect(bankersDivide256(Wide256Magnitude(magnitude, times: 1), by: 1, sign: .negative) == Int128.min)
    }

    @Test("A quotient one past the maximum returns nil")
    func outOfRangeIsNil() {
        let magnitude = UInt128(1) << 127   // one past Int128.max as a positive value

        #expect(bankersDivide256(Wide256Magnitude(magnitude, times: 1), by: 1, sign: .positive) == nil)
    }

    @Test("A whole part that needs more than one word returns nil")
    func overflowingWholePartIsNil() {
        #expect(bankersDivide256(Wide256Magnitude(.max, times: .max), by: 1, sign: .positive) == nil)
    }

    @Test("Matches a direct Int128 oracle for products that fit Int128", arguments: [
        (UInt128(7), UInt128(11), UInt128(3)),
        (UInt128(100), UInt128(100), UInt128(7)),
        (UInt128(12_345), UInt128(6_789), UInt128(13)),
        (UInt128(1_000_000), UInt128(1), UInt128(2)),
        (UInt128(2), UInt128(3), UInt128(4)),
        (UInt128(999), UInt128(1_001), UInt128(500)),
    ])
    func matchesReference(_ operands: (magnitude: UInt128, factor: UInt128, divisor: UInt128)) {
        let product = Int128(operands.magnitude) * Int128(operands.factor)
        let expected = bankerReference(product: product, dividedBy: Int128(operands.divisor))

        let actual = bankersDivide256(
            Wide256Magnitude(operands.magnitude, times: operands.factor),
            by: operands.divisor,
            sign: .positive
        )

        #expect(actual == expected)
    }
}

// Independent banker's-rounding oracle in plain Int128, valid only when the product fits Int128.
private func bankerReference(product: Int128, dividedBy divisor: Int128) -> Int128 {
    let quotient = product / divisor
    let remainder = product % divisor
    let twiceRemainder = remainder * 2

    if twiceRemainder < divisor {
        return quotient
    }
    if twiceRemainder > divisor {
        return quotient + 1
    }
    return quotient.isMultiple(of: 2) ? quotient : quotient + 1
}

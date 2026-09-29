import SwiftMoneyCore
import Testing

private typealias Credits = MoneyOf<Millicredits>

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private func runtimeStride(_ minorUnits: Int64, _ currency: Currency = .gbp) throws -> Money.Stride {
    try #require(Money.Stride(exactly: Money(minorUnits: minorUnits, currency: currency)))
}

@Suite("stride over amounts")
struct StrideFunctionsTests {

    @Test("£10 through £250 by £100 is £10, £110 and £210, as stride over Int would give")
    func throughStopsBeforeAnOffStepEnd() {
        let amounts = stride(from: GBP(minorUnits: 10_00), through: GBP(minorUnits: 250_00), by: .majorUnits(100))

        #expect(Array(amounts) == [GBP(minorUnits: 10_00), GBP(minorUnits: 110_00), GBP(minorUnits: 210_00)])
    }

    @Test("through includes an end a step lands on; to excludes it")
    func endOnAStep() {
        let start = JPY(minorUnits: 0)
        let end = JPY(minorUnits: 300)

        #expect(Array(stride(from: start, through: end, by: .minorUnits(100))).map(\.minorUnits) == [0, 100, 200, 300])
        #expect(Array(stride(from: start, to: end, by: .minorUnits(100))).map(\.minorUnits) == [0, 100, 200])
    }

    @Test("A negative stride counts down")
    func negativeCountsDown() {
        let amounts = stride(from: GBP(minorUnits: 250_00), through: GBP(minorUnits: 10_00), by: .majorUnits(-100))

        #expect(Array(amounts) == [GBP(minorUnits: 250_00), GBP(minorUnits: 150_00), GBP(minorUnits: 50_00)])
    }

    @Test("Stepping away from the end is empty; stepping to the start is empty, through it holds only it")
    func awayFromEndIsEmpty() {
        let ten = Credits(minorUnits: 10_000)
        let twenty = Credits(minorUnits: 20_000)

        #expect(Array(stride(from: ten, to: twenty, by: .majorUnits(-1))).isEmpty)
        #expect(Array(stride(from: twenty, through: ten, by: .majorUnit)).isEmpty)
        #expect(Array(stride(from: ten, to: ten, by: .minorUnit)).isEmpty)
        #expect(Array(stride(from: ten, through: ten, by: .minorUnit)) == [ten])
    }

    @Test("A stride above Int32.max steps without trapping, as it must on 32-bit watchOS")
    func strideAboveInt32Max() {
        let big = Int64(Int32.max) + 1
        let amounts = stride(from: GBP.zero, through: GBP(minorUnits: 2 * big), by: .minorUnits(2_147_483_648))

        #expect(Array(amounts).map(\.minorUnits) == [0, big, 2 * big])
    }

    @Test("A step past the largest or smallest amount ends the sequence rather than trapping")
    func overflowEnds() {
        let nearMax = GBP(minorUnits: Int64.max - 1)
        let nearMin = GBP(minorUnits: Int64.min + 1)

        #expect(Array(stride(from: nearMax, through: .max, by: .minorUnits(5))) == [nearMax])
        #expect(Array(stride(from: nearMax, to: .max, by: .minorUnits(5))) == [nearMax])
        #expect(Array(stride(from: nearMin, through: .min, by: .minorUnits(-5))) == [nearMin])
        #expect(Array(stride(from: GBP.max, through: .max, by: .minorUnit)) == [GBP.max])
        #expect(Array(stride(from: GBP.min, through: .max, by: .minorUnits(9_223_372_036_854_775_807))).count == 3)
    }

    @Test("Runtime amounts stride as typed ones do, in their currency")
    func runtimeMatchesTyped() throws {
        let through = try stride(from: pounds(10_00), through: pounds(250_00), by: #require(.majorUnits(100, of: .gbp)))
        let to = try stride(from: pounds(250_00), to: pounds(50_00), by: runtimeStride(-100_00))

        #expect(Array(through) == [pounds(10_00), pounds(110_00), pounds(210_00)])
        #expect(Array(to) == [pounds(250_00), pounds(150_00)])
    }

    @Test("A runtime end or stride in another currency throws a mismatch, the start's currency first")
    func runtimeMismatch() throws {
        let yen = Money(minorUnits: 500, currency: .jpy)
        let poundStride = try runtimeStride(1_00)
        let yenStride = try runtimeStride(1, .jpy)
        let mismatch = MoneyError.currencyMismatch(lhs: .gbp, rhs: .jpy)

        #expect(throws: mismatch) { try stride(from: pounds(0), to: yen, by: poundStride) }
        #expect(throws: mismatch) { try stride(from: pounds(0), through: yen, by: poundStride) }
        #expect(throws: mismatch) { try stride(from: pounds(0), to: pounds(5_00), by: yenStride) }
        #expect(throws: mismatch) { try stride(from: pounds(0), through: pounds(5_00), by: yenStride) }
    }

    @Test("The end is checked before the stride")
    func runtimeEndCheckedFirst() throws {
        let euros = Money(minorUnits: 500, currency: .eur)
        let yenStride = try runtimeStride(1, .jpy)

        #expect(throws: MoneyError.currencyMismatch(lhs: .gbp, rhs: .eur)) {
            try stride(from: pounds(0), through: euros, by: yenStride)
        }
    }

    @Test("A sequence reports its length ahead, and rules out amounts outside it without stepping")
    func countAndContains() throws {
        let amounts = stride(from: GBP(minorUnits: 10_00), through: GBP(minorUnits: 250_00), by: .majorUnits(100))
        let upTo = stride(from: GBP(minorUnits: 250_00), to: GBP(minorUnits: 10_00), by: .majorUnits(-100))

        #expect(amounts.underestimatedCount == 3)
        #expect(upTo.underestimatedCount == 3)
        #expect(amounts.contains(GBP(minorUnits: 110_00)))
        #expect(!amounts.contains(GBP(minorUnits: 111_00)))
        #expect(!amounts.contains(GBP(minorUnits: 5_00)))
        #expect(!amounts.contains(GBP(minorUnits: 260_00)))
        #expect(upTo.contains(GBP(minorUnits: 50_00)))
        #expect(!upTo.contains(GBP(minorUnits: 10_00)))
        #expect(!upTo.contains(GBP(minorUnits: 260_00)))
    }

    @Test("stride over Int still type-checks with SwiftMoneyCore imported")
    func integerStrideUnaffected() {
        #expect(Array(stride(from: 0, to: 10, by: 2)) == [0, 2, 4, 6, 8])
        #expect(Array(stride(from: 0, through: 10, by: 5)) == [0, 5, 10])
    }
}

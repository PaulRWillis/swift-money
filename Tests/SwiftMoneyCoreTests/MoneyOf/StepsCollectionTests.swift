import SwiftMoneyCore
import Testing

private func pounds(_ minorUnits: Int64) -> Money {
    Money(minorUnits: minorUnits, currency: .gbp)
}

private func tenToTwoFiftyByAHundred() throws -> GBP.Steps {
    try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(100))
}

@Suite("MoneyOf.Steps as a collection")
struct StepsCollectionTests {

    @Test("count matches iterating, and steps are never empty")
    func countMatchesIteration() throws {
        let steps = try tenToTwoFiftyByAHundred()
        let one = try (GBP.zero ... .zero).steps(by: .minorUnit)

        #expect(steps.count == Array(steps).count)
        #expect(steps.isEmpty == false)
        #expect(one.count == 1)
        #expect(one.isEmpty == false)
        #expect(one.first == .zero)
    }

    @Test("Indices run from startIndex to endIndex, one apart each way")
    func indexAfterAndBefore() throws {
        let steps = try tenToTwoFiftyByAHundred()
        let second = steps.index(after: steps.startIndex)

        #expect(steps[second] == GBP(minorUnits: 110_00))
        #expect(steps.index(before: second) == steps.startIndex)
        #expect(steps.index(before: steps.endIndex) == 3)
        #expect(steps.startIndex == 0)
        #expect(steps.endIndex == 4)
        #expect(steps.startIndex < steps.endIndex)
    }

    @Test("Offsetting an index and measuring the distance back round-trip")
    func offsetAndDistance() throws {
        let steps = try tenToTwoFiftyByAHundred()
        let third = steps.index(steps.startIndex, offsetBy: 2)

        #expect(steps[third] == GBP(minorUnits: 210_00))
        #expect(steps.distance(from: steps.startIndex, to: third) == 2)
        #expect(steps.distance(from: third, to: steps.startIndex) == -2)
        #expect(steps.index(third, offsetBy: -2) == steps.startIndex)
        #expect(steps.distance(from: steps.startIndex, to: steps.endIndex) == steps.count)
    }

    @Test("Offsetting past a limit is nil, in either direction; up to it is the limit")
    func offsetLimitedBy() throws {
        let steps = try tenToTwoFiftyByAHundred()
        let start = steps.startIndex
        let end = steps.endIndex

        #expect(steps.index(start, offsetBy: 4, limitedBy: end) == end)
        #expect(steps.index(start, offsetBy: 5, limitedBy: end) == nil)
        #expect(steps.index(end, offsetBy: -4, limitedBy: start) == start)
        #expect(steps.index(end, offsetBy: -5, limitedBy: start) == nil)
        #expect(steps.index(start, offsetBy: 2, limitedBy: start) == nil)
        #expect(steps.index(end, offsetBy: 1, limitedBy: start) == 5)
        #expect(steps.index(start, offsetBy: 0, limitedBy: start) == start)
    }

    @Test("indices, reversed() and slices follow the steps")
    func indicesAndReversed() throws {
        let steps = try tenToTwoFiftyByAHundred()

        #expect(steps.indices.map { steps[$0] } == Array(steps))
        #expect(steps.reversed().map(\.minorUnits) == [250_00, 210_00, 110_00, 10_00])
        #expect(steps.dropFirst().map(\.minorUnits) == [110_00, 210_00, 250_00])
        #expect(steps.last == GBP(minorUnits: 250_00))
    }

    @Test("firstIndex(of:) and contains find a step without walking, and miss an amount between steps")
    func findsExactSteps() throws {
        let steps = try tenToTwoFiftyByAHundred()
        let down = try (GBP(minorUnits: 10_00) ... GBP(minorUnits: 250_00)).steps(by: .majorUnits(-100))

        #expect(steps.firstIndex(of: GBP(minorUnits: 210_00)) == 2)
        #expect(steps.firstIndex(of: GBP(minorUnits: 250_00)) == 3)
        #expect(steps.lastIndex(of: GBP(minorUnits: 10_00)) == 0)
        #expect(steps.firstIndex(of: GBP(minorUnits: 200_00)) == nil)
        #expect(steps.firstIndex(of: GBP(minorUnits: 310_00)) == nil)
        #expect(steps.firstIndex(of: GBP(minorUnits: -90_00)) == nil)
        #expect(steps.contains(GBP(minorUnits: 110_00)))
        #expect(steps.contains(GBP(minorUnits: 9_99)) == false)
        #expect(down.firstIndex(of: GBP(minorUnits: 150_00)) == 1)
        #expect(down.firstIndex(of: GBP(minorUnits: 10_00)) == 3)
        #expect(down.firstIndex(of: GBP(minorUnits: 350_00)) == nil)
    }

    @Test("Finding a step among 2⁶⁴ − 1 minor units' worth of steps does not walk them")
    func findsInTheWholeWidth() throws {
        let steps = try (GBP.min ... GBP.max).steps(by: .minorUnits(4_611_686_018_427_387_904))

        #expect(steps.firstIndex(of: .zero) == 2)
        #expect(steps.firstIndex(of: .max) == 4)
        #expect(steps.firstIndex(of: GBP(minorUnits: 1)) == nil)
    }

    @Test("Among Int.max steps, firstIndex(of:), lastIndex(of:) and contains answer without walking them")
    func lookupsTakeConstantTime() throws {
        let farBound = Int64(Int.max) - 1
        let range = GBP.zero ... GBP(minorUnits: farBound)
        let up = try range.steps(by: .minorUnit)
        let down = try range.steps(by: .minorUnits(-1))
        let middle = GBP(minorUnits: Int64(Int.max / 2))
        let offset = { (steps: GBP.Steps, index: GBP.Steps.Index?) in
            index.map { steps.distance(from: steps.startIndex, to: $0) }
        }

        #expect(offset(up, up.firstIndex(of: middle)) == Int.max / 2)
        #expect(offset(up, up.firstIndex(of: GBP(minorUnits: farBound))) == Int.max - 1)
        // A backward scan finds each sequence's last element first, so for `lastIndex(of:)` only the
        // middle lookups show the steps aren't walked.
        #expect(offset(up, up.lastIndex(of: middle)) == Int.max / 2)
        #expect(offset(up, up.lastIndex(of: GBP(minorUnits: farBound))) == Int.max - 1)
        #expect(up.contains(middle))
        #expect(up.contains(GBP(minorUnits: farBound)))
        #expect(offset(down, down.lastIndex(of: middle)) == Int.max / 2)
        #expect(offset(down, down.lastIndex(of: .zero)) == Int.max - 1)
    }

    @Test("A runtime amount in another currency is not a step")
    func runtimeMismatchIsNotFound() throws {
        let steps = try (pounds(10_00)...pounds(250_00)).steps(by: #require(.majorUnits(100, of: .gbp)))

        #expect(steps.firstIndex(of: pounds(110_00)) == 1)
        #expect(steps.firstIndex(of: Money(minorUnits: 110_00, currency: .eur)) == nil)
        #expect(steps.contains(Money(minorUnits: 250_00, currency: .eur)) == false)
    }

    #if EXIT_TESTS_SUPPORTED
    @Test("A position outside the steps traps, as Array's subscript does")
    func subscriptOutsideTraps() async {
        await #expect(processExitsWith: .failure) {
            let steps = try (GBP.zero ... GBP(minorUnits: 10)).steps(by: .minorUnits(5))
            blackHole(steps[steps.endIndex])
        }
        await #expect(processExitsWith: .failure) {
            let steps = try (GBP.zero ... GBP(minorUnits: 10)).steps(by: .minorUnits(5))
            blackHole(steps[steps.index(before: steps.startIndex)])
        }
    }
    #endif
}

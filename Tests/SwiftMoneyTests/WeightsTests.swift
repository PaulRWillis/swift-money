import SwiftMoney
import Testing

@Suite("Weights Tests")
struct WeightsTests {

    @Test("Init from a single weight succeeds")
    func initFromSingleWeight() {
        #expect(Weights(exactly: [1]) != nil)
    }

    @Test("Init from proportional weights succeeds")
    func initFromProportionalWeights() {
        #expect(Weights(exactly: [60, 30, 10]) != nil)
    }

    @Test("Init from a zero weight among others succeeds")
    func initFromZeroWeightAmongOthers() {
        #expect(Weights(exactly: [0, 1]) != nil)
    }

    @Test("Init from the biggest weight succeeds")
    func initFromBiggestWeight() {
        #expect(Weights(exactly: [Weight(integerLiteral: Int.max)]) != nil)
    }

    @Test("Init from an empty list returns nil")
    func initFromEmptyList() {
        #expect(Weights(exactly: []) == nil)
    }

    @Test("Init from weights whose sum overflows returns nil")
    func initFromOverflowingSum() {
        #expect(Weights(exactly: [Weight(integerLiteral: Int.max), 1]) == nil)
    }

    @Test("Init from two biggest weights returns nil")
    func initFromTwoBiggestWeights() {
        let biggest = Weight(integerLiteral: Int.max)
        #expect(Weights(exactly: [biggest, biggest]) == nil)
    }

    @Test("Init from a single zero weight returns nil")
    func initFromSingleZeroWeight() {
        #expect(Weights(exactly: [0]) == nil)
    }

    @Test("Init from all-zero weights returns nil")
    func initFromAllZeroWeights() {
        #expect(Weights(exactly: [0, 0]) == nil)
    }

    @Test("Literal: Init from proportional weights succeeds")
    func initFromProportionalWeightsLiteral() async {
        await #expect(processExitsWith: .success) {
            _ = [60, 30, 10] as Weights
        }
    }

    @Test("Literal: Init from an empty list traps")
    func initFromEmptyListLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = [] as Weights
        }
    }

    @Test("Literal: Init from all-zero weights traps")
    func initFromAllZeroWeightsLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = [0, 0] as Weights
        }
    }

    @Test("Literal: Init from weights whose sum overflows traps")
    func initFromOverflowingSumLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = [9223372036854775807, 1] as Weights
        }
    }

    @Test("A literal equals its validated counterpart")
    func literalEqualsValidatedCounterpart() {
        #expect(Weights(exactly: [60, 30, 10]) == [60, 30, 10])
    }

    @Test("Equal weights are equatable")
    func equalWeightsAreEquatable() throws {
        let a = try #require(Weights(exactly: [60, 30, 10]))
        let b = try #require(Weights(exactly: [60, 30, 10]))

        #expect(a == b)
    }

    @Test("Differently ordered weights are not equal")
    func differentlyOrderedWeightsAreNotEqual() throws {
        let descending = try #require(Weights(exactly: [60, 30, 10]))
        let ascending = try #require(Weights(exactly: [10, 30, 60]))

        #expect(descending != ascending)
    }
}

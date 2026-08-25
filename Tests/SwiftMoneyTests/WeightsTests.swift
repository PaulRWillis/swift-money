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
        #expect(Weights(exactly: [Int.max]) != nil)
    }

    @Test("Init from an empty list returns nil")
    func initFromEmptyList() {
        #expect(Weights(exactly: []) == nil)
    }

    @Test("Init from a negative weight returns nil")
    func initFromNegativeWeight() {
        #expect(Weights(exactly: [-1]) == nil)
    }

    @Test("Init from a negative weight among others returns nil")
    func initFromNegativeWeightAmongOthers() {
        #expect(Weights(exactly: [1, -1]) == nil)
    }

    @Test("Init from weights whose sum overflows returns nil")
    func initFromOverflowingSum() {
        #expect(Weights(exactly: [Int.max, 1]) == nil)
    }

    @Test("Init from two biggest weights returns nil")
    func initFromTwoBiggestWeights() {
        #expect(Weights(exactly: [Int.max, Int.max]) == nil)
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

    @Test("Literal: Init from a negative weight traps")
    func initFromNegativeWeightLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = [-1] as Weights
        }
    }

    @Test("Literal: Init from all-zero weights traps")
    func initFromAllZeroWeightsLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = [0, 0] as Weights
        }
    }

    @Test("A literal equals its validated counterpart")
    func literalEqualsValidatedCounterpart() {
        #expect(Weights(exactly: [60, 30, 10]) == [60, 30, 10])
    }

    @Test("Equal weights are equatable")
    func equalWeightsAreEquatable() {
        let a = Weights(exactly: [60, 30, 10])
        let b = Weights(exactly: [60, 30, 10])

        #expect(a == b)
        #expect(a != nil)
    }
}

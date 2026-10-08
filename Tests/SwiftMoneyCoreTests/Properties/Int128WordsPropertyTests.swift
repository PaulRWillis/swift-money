import SwiftMoneyCore
import Testing

// Two operands, each checked against the standard library's `Int128` doing the same operation.
private struct SignedPair: Sendable, CustomTestStringConvertible {
    let lhs: Int128Words
    let rhs: Int128Words

    var testDescription: String {
        "\(lhs), \(rhs)"
    }
}

private let signedPairs: [SignedPair] = samples(
    zip(Gen<Int128Words>.anySignedWords, Gen<Int128Words>.anySignedWords).map { SignedPair(lhs: $0, rhs: $1) },
    seed: PropertySeed.signedWords,
    edges: Gen<Int128Words>.signedBoundaries.flatMap { lhs in
        Gen<Int128Words>.signedBoundaries.map { SignedPair(lhs: lhs, rhs: $0) }
    }
)

@Suite("Int128Words matches Int128")
struct Int128WordsPropertyTests {

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("An Int64 converts to the same value", arguments: signedPairs)
    private func convertsAnInt64(_ pair: SignedPair) {
        let word = Int64(truncatingIfNeeded: Int128(words: pair.lhs))

        #expect(Int128(words: Int128Words(word)) == Int128(word))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Converting exactly from a wider or narrower integer matches", arguments: signedPairs)
    private func convertsExactly(_ pair: SignedPair) {
        let signed = Int128(words: pair.lhs)
        let unsigned = UInt128(words: UInt128Words(bitPattern: pair.lhs))
        let narrow = Int8(truncatingIfNeeded: signed)

        #expect(Int128Words(exactly: signed).map(Int128.init(words:)) == signed)
        #expect(Int128Words(exactly: unsigned).map(Int128.init(words:)) == Int128(exactly: unsigned))
        #expect(Int128Words(exactly: narrow).map(Int128.init(words:)) == Int128(narrow))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Converting exactly to Int64 matches", arguments: signedPairs)
    private func convertsExactlyToInt64(_ pair: SignedPair) {
        #expect(Int64(exactly: pair.lhs) == Int64(exactly: Int128(words: pair.lhs)))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Equality and order match", arguments: signedPairs)
    private func comparing(_ pair: SignedPair) {
        let lhs = Int128(words: pair.lhs)
        let rhs = Int128(words: pair.rhs)

        #expect((pair.lhs == pair.rhs) == (lhs == rhs))
        #expect((pair.lhs < pair.rhs) == (lhs < rhs))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("The magnitude and sign match", arguments: signedPairs)
    private func magnitudeAndSign(_ pair: SignedPair) {
        let value = Int128(words: pair.lhs)

        #expect(UInt128(words: pair.lhs.magnitude) == value.magnitude)
        #expect(Sign(of: pair.lhs) == Sign(of: value))
    }

    @Test("Rebuilding from the magnitude and sign gives the value back", arguments: signedPairs)
    private func rebuildingFromMagnitudeAndSign(_ pair: SignedPair) {
        #expect(Int128Words(magnitude: pair.lhs.magnitude, sign: Sign(of: pair.lhs)) == pair.lhs)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Adding reports the same sum and overflow", arguments: signedPairs)
    private func adding(_ pair: SignedPair) {
        let expected = Int128(words: pair.lhs).addingReportingOverflow(Int128(words: pair.rhs))
        let actual = pair.lhs.addingReportingOverflow(pair.rhs)

        #expect(Int128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
        if !expected.overflow {
            #expect(Int128(words: pair.lhs + pair.rhs) == expected.partialValue)
        }
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Subtracting reports the same difference and overflow", arguments: signedPairs)
    private func subtracting(_ pair: SignedPair) {
        let expected = Int128(words: pair.lhs).subtractingReportingOverflow(Int128(words: pair.rhs))
        let actual = pair.lhs.subtractingReportingOverflow(pair.rhs)

        #expect(Int128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
        if !expected.overflow {
            #expect(Int128(words: pair.lhs - pair.rhs) == expected.partialValue)
        }
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Multiplying reports the same product and overflow", arguments: signedPairs)
    private func multiplying(_ pair: SignedPair) {
        let expected = Int128(words: pair.lhs).multipliedReportingOverflow(by: Int128(words: pair.rhs))
        let actual = pair.lhs.multipliedReportingOverflow(by: pair.rhs)

        #expect(Int128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
        if !expected.overflow {
            var product = pair.lhs
            product *= pair.rhs
            #expect(Int128(words: pair.lhs * pair.rhs) == expected.partialValue)
            #expect(Int128(words: product) == expected.partialValue)
        }
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Multiplying by an Int64 reports the same product and overflow", arguments: signedPairs)
    private func multiplyingByAnInt64(_ pair: SignedPair) {
        let factor = Int64(truncatingIfNeeded: Int128(words: pair.rhs))
        let expected = Int128(words: pair.lhs).multipliedReportingOverflow(by: Int128(factor))
        let actual = pair.lhs.multipliedReportingOverflow(byInt64: factor)

        #expect(Int128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Dividing gives the same quotient", arguments: signedPairs)
    private func dividing(_ pair: SignedPair) {
        let lhs = Int128(words: pair.lhs)
        let rhs = Int128(words: pair.rhs)
        let (expected, overflow) = lhs.dividedReportingOverflow(by: rhs)
        guard rhs != 0, !overflow else {
            return
        }

        #expect(Int128(words: pair.lhs / pair.rhs) == expected)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Negating gives the same value", arguments: signedPairs)
    private func negating(_ pair: SignedPair) {
        guard pair.lhs != .min else {
            return
        }

        #expect(Int128(words: -pair.lhs) == -Int128(words: pair.lhs))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Converting to Double gives the same bits", arguments: signedPairs)
    private func convertsToDouble(_ pair: SignedPair) {
        #expect(Double(pair.lhs).bitPattern == Double(Int128(words: pair.lhs)).bitPattern)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Parsing decimal text gives the same value", arguments: signedPairs)
    private func parsing(_ pair: SignedPair) {
        let value = Int128(words: pair.lhs)
        let wide = UInt128(words: UInt128Words(bitPattern: pair.rhs))
        let texts = [
            String(value),
            "+" + String(value.magnitude),
            "-" + String(value.magnitude),
            String(value) + "7",
            "-" + String(wide),
            String(wide),
        ]

        for text in texts {
            #expect(Int128Words(text).map(Int128.init(words:)) == Int128(text), "\(text)")
        }
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Multiplying by ten and adding a digit matches", arguments: signedPairs)
    private func multiplyingByTenAdding(_ pair: SignedPair) {
        let value = UInt128Words(bitPattern: pair.lhs)
        let digit = UInt8(truncatingIfNeeded: pair.rhs.magnitude.low % 10)
        let (shifted, shiftOverflow) = UInt128(words: value).multipliedReportingOverflow(by: 10)
        let (sum, sumOverflow) = shifted.addingReportingOverflow(UInt128(digit))

        #expect(value.multipliedByTenAdding(digit).map(UInt128.init(words:)) == (shiftOverflow || sumOverflow ? nil : sum))
    }
}

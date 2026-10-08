import SwiftMoneyCore
import Testing

// Two operands, each checked against the standard library's `UInt128` doing the same operation.
private struct UnsignedPair: Sendable, CustomTestStringConvertible {
    let lhs: UInt128Words
    let rhs: UInt128Words

    var testDescription: String {
        "\(lhs), \(rhs)"
    }
}

// Three values that become a 256-bit dividend and a divisor once the dividend's high half is reduced
// below the divisor, so the quotient fits 128 bits.
private struct UnsignedTriple: Sendable, CustomTestStringConvertible {
    let divisor: UInt128Words
    let high: UInt128Words
    let low: UInt128Words

    var testDescription: String {
        "(\(high), \(low)) ÷ \(divisor)"
    }
}

// A value and a shift amount, negative and past the width included.
private struct UnsignedShift: Sendable, CustomTestStringConvertible {
    let value: UInt128Words
    let shift: Int

    var testDescription: String {
        "\(value) by \(shift)"
    }
}

private let unsignedPairs: [UnsignedPair] = samples(
    zip(Gen<UInt128Words>.anyWords, Gen<UInt128Words>.anyWords).map { UnsignedPair(lhs: $0, rhs: $1) },
    seed: PropertySeed.unsignedWords,
    edges: Gen<UInt128Words>.wordBoundaries.flatMap { lhs in
        Gen<UInt128Words>.wordBoundaries.map { UnsignedPair(lhs: lhs, rhs: $0) }
    }
)

private let unsignedTriples: [UnsignedTriple] = samples(
    zip3(Gen<UInt128Words>.anyWords, Gen<UInt128Words>.anyWords, Gen<UInt128Words>.anyWords).map {
        UnsignedTriple(divisor: $0, high: $1, low: $2)
    },
    seed: PropertySeed.unsignedWords,
    edges: Gen<UInt128Words>.wordBoundaries.flatMap { divisor in
        [
            UnsignedTriple(divisor: divisor, high: .min, low: .min),
            UnsignedTriple(divisor: divisor, high: .max, low: .max),
            UnsignedTriple(divisor: divisor, high: divisor, low: .max),
        ]
    }
)

private let unsignedShifts: [UnsignedShift] = samples(
    zip(Gen<UInt128Words>.anyWords, Gen<Int64>.int(in: -140 ... 140)).map { UnsignedShift(value: $0, shift: Int($1)) },
    seed: PropertySeed.unsignedWords,
    edges: [0, 1, 63, 64, 65, 127, 128, -1, -64, -127, -128, Int.max, Int.min].map {
        UnsignedShift(value: .max, shift: $0)
    }
)

@Suite("UInt128Words matches UInt128")
struct UInt128WordsPropertyTests {

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("A UInt64 converts to the same value", arguments: unsignedPairs)
    private func convertsAWord(_ pair: UnsignedPair) {
        #expect(UInt128(words: UInt128Words(pair.lhs.low)) == UInt128(pair.lhs.low))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Equality and order match", arguments: unsignedPairs)
    private func comparing(_ pair: UnsignedPair) {
        let lhs = UInt128(words: pair.lhs)
        let rhs = UInt128(words: pair.rhs)

        #expect((pair.lhs == pair.rhs) == (lhs == rhs))
        #expect((pair.lhs < pair.rhs) == (lhs < rhs))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Adding reports the same sum and overflow", arguments: unsignedPairs)
    private func adding(_ pair: UnsignedPair) {
        let expected = UInt128(words: pair.lhs).addingReportingOverflow(UInt128(words: pair.rhs))
        let actual = pair.lhs.addingReportingOverflow(pair.rhs)

        #expect(UInt128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Subtracting reports the same difference and overflow", arguments: unsignedPairs)
    private func subtracting(_ pair: UnsignedPair) {
        let expected = UInt128(words: pair.lhs).subtractingReportingOverflow(UInt128(words: pair.rhs))
        let actual = pair.lhs.subtractingReportingOverflow(pair.rhs)

        #expect(UInt128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Subtracting the smaller from the larger gives the same difference", arguments: unsignedPairs)
    private func subtractingWithoutOverflow(_ pair: UnsignedPair) {
        let lhs = UInt128(words: pair.lhs)
        let rhs = UInt128(words: pair.rhs)
        let difference = lhs < rhs ? pair.rhs - pair.lhs : pair.lhs - pair.rhs

        #expect(UInt128(words: difference) == max(lhs, rhs) - min(lhs, rhs))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Multiplying reports the same product and overflow", arguments: unsignedPairs)
    private func multiplying(_ pair: UnsignedPair) {
        let expected = UInt128(words: pair.lhs).multipliedReportingOverflow(by: UInt128(words: pair.rhs))
        let actual = pair.lhs.multipliedReportingOverflow(by: pair.rhs)

        #expect(UInt128(words: actual.partialValue) == expected.partialValue)
        #expect(actual.overflow == expected.overflow)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Multiplying full width gives the same 256-bit product", arguments: unsignedPairs)
    private func multiplyingFullWidth(_ pair: UnsignedPair) {
        let expected = UInt128(words: pair.lhs).multipliedFullWidth(by: UInt128(words: pair.rhs))
        let actual = pair.lhs.multipliedFullWidth(by: pair.rhs)

        #expect(UInt128(words: actual.high) == expected.high)
        #expect(UInt128(words: actual.low) == expected.low)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Dividing a 256-bit value gives the same quotient and remainder", arguments: unsignedTriples)
    private func dividingFullWidth(_ triple: UnsignedTriple) {
        let divisor = max(UInt128(words: triple.divisor), 1)
        let high = UInt128(words: triple.high) % divisor
        let low = UInt128(words: triple.low)

        let expected = divisor.dividingFullWidth((high, low))
        let actual = UInt128Words(stdlib: divisor).dividingFullWidth(
            (high: UInt128Words(stdlib: high), low: triple.low)
        )

        #expect(UInt128(words: actual.quotient) == expected.quotient)
        #expect(UInt128(words: actual.remainder) == expected.remainder)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Dividing gives the same quotient and remainder", arguments: unsignedPairs)
    private func dividing(_ pair: UnsignedPair) {
        let divisor = max(UInt128(words: pair.rhs), 1)
        let expected = UInt128(words: pair.lhs).quotientAndRemainder(dividingBy: divisor)
        let actual = pair.lhs.quotientAndRemainder(dividingBy: UInt128Words(stdlib: divisor))

        #expect(UInt128(words: actual.quotient) == expected.quotient)
        #expect(UInt128(words: actual.remainder) == expected.remainder)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Shifting left gives the same value", arguments: unsignedShifts)
    private func shiftingLeft(_ shift: UnsignedShift) {
        #expect(UInt128(words: shift.value << shift.shift) == UInt128(words: shift.value) << shift.shift)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Shifting right gives the same value", arguments: unsignedShifts)
    private func shiftingRight(_ shift: UnsignedShift) {
        #expect(UInt128(words: shift.value >> shift.shift) == UInt128(words: shift.value) >> shift.shift)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Or-ing gives the same bits", arguments: unsignedPairs)
    private func orBits(_ pair: UnsignedPair) {
        #expect(UInt128(words: pair.lhs | pair.rhs) == UInt128(words: pair.lhs) | UInt128(words: pair.rhs))
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    @Test("Parity matches being a multiple of two", arguments: unsignedPairs)
    private func parity(_ pair: UnsignedPair) {
        #expect((pair.lhs.parity == .even) == UInt128(words: pair.lhs).isMultiple(of: 2))
        #expect(Parity(of: pair.lhs) == pair.lhs.parity)
    }
}

// A deterministic pseudo-random number generator for the property tests.
//
// SplitMix64: one 64-bit word of state advanced by a fixed odd increment, each output passed through a
// well-known bit-mixing finalizer. Conforming to the standard library's `RandomNumberGenerator` means
// the whole `.random(in:using:)` family drives it, and a given seed yields the same stream on every
// platform, with no Foundation. It is the strong seed type the harness threads through generators, never
// a raw `Int`.
struct Seed: RandomNumberGenerator {
    private var state: UInt64

    /// Creates a generator whose stream is fixed by `seed`.
    init(_ seed: UInt64) {
        self.state = seed
    }

    /// Returns the next value in the stream and advances the state.
    mutating func next() -> UInt64 {
        state = state &+ Self.increment

        var mixed = state
        mixed = (mixed ^ (mixed >> Self.firstShift)) &* Self.firstMultiplier
        mixed = (mixed ^ (mixed >> Self.secondShift)) &* Self.secondMultiplier

        return mixed ^ (mixed >> Self.finalShift)
    }
}

private extension Seed {
    // The SplitMix64 constants, from the reference implementation. The increment is the odd 64-bit
    // fraction of the golden ratio; the multipliers and shifts are the published finalizer that spreads
    // each state word across all 64 output bits. Named rather than inlined so they read as the algorithm
    // rather than as arbitrary numbers, and every operation is wrapping (`&+`, `&*`, `>>`) by design.
    static let increment: UInt64 = 0x9E37_79B9_7F4A_7C15
    static let firstMultiplier: UInt64 = 0xBF58_476D_1CE4_E5B9
    static let secondMultiplier: UInt64 = 0x94D0_49BB_1331_11EB
    static let firstShift: UInt64 = 30
    static let secondShift: UInt64 = 27
    static let finalShift: UInt64 = 31
}

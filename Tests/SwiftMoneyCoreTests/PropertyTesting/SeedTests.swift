import Testing

@Suite("Seed")
struct SeedTests {

    // How many values a stream comparison draws. Enough that two independent streams matching by chance
    // is not credible, cheap enough to run in every configuration.
    private static let streamLength = 64

    private static func stream(from seed: UInt64) -> [UInt64] {
        var generator = Seed(seed)

        return (0 ..< streamLength).map { _ in generator.next() }
    }

    @Test("The same seed yields the same stream")
    func sameSeedSameStream() {
        #expect(Self.stream(from: 1) == Self.stream(from: 1))
    }

    @Test("Different seeds yield different streams")
    func differentSeedsDiverge() {
        #expect(Self.stream(from: 1) != Self.stream(from: 2))
    }

    @Test("A seed of zero still produces a varied stream")
    func zeroSeedIsNotDegenerate() {
        let values = Self.stream(from: 0)

        // SplitMix64's finalizer means even a zero seed mixes to varied output rather than a run of
        // zeros, which is the reason to use it over a bare linear congruential generator.
        #expect(values.contains { $0 != 0 })
        #expect(Set(values).count == values.count)
    }

    @Test("Bounded draws stay within their range")
    func boundedDrawsStayInRange() {
        var generator = Seed(1)
        let range: ClosedRange<Int64> = -10 ... 10

        for _ in 0 ..< Self.streamLength {
            let value = Int64.random(in: range, using: &generator)

            #expect(range.contains(value))
        }
    }

    @Test("Drawing from a range covers both ends over enough draws")
    func boundedDrawsCoverTheRange() {
        var generator = Seed(1)
        let range: ClosedRange<Int64> = 0 ... 1

        var drawn: Set<Int64> = []
        for _ in 0 ..< Self.streamLength {
            drawn.insert(Int64.random(in: range, using: &generator))
        }

        #expect(drawn == [0, 1])
    }
}

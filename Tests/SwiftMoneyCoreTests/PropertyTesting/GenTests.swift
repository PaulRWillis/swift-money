import Testing

@Suite("Gen")
struct GenTests {

    // A fixed seed for every case, so each law is checked against a known stream rather than a fresh one.
    private static let seed: UInt64 = 42
    private static let drawCount = 64

    private static func draws<Value>(_ gen: Gen<Value>) -> [Value] {
        var generator = Seed(seed)

        return (0 ..< drawCount).map { _ in gen.run(&generator) }
    }

    @Test("always yields its value and draws nothing")
    func alwaysIsConstant() {
        var generator = Seed(Self.seed)
        let before = generator.next()

        var again = Seed(Self.seed)
        let value = Gen.always(7).run(&again)
        let after = again.next()

        #expect(value == 7)
        #expect(before == after)   // the constant generator advanced the stream not at all
    }

    @Test("int stays within its range")
    func intStaysInRange() {
        let range: ClosedRange<Int64> = -5 ... 5

        for value in Self.draws(.int(in: range)) {
            #expect(range.contains(value))
        }
    }

    @Test("element picks only from the given values")
    func elementPicksFromSet() {
        let elements = [10, 20, 30]

        for value in Self.draws(.element(of: elements)) {
            #expect(elements.contains(value))
        }
    }

    @Test("map obeys the identity law")
    func mapIdentity() {
        let gen = Gen.int(in: 0 ... 1_000)

        #expect(Self.draws(gen.map { $0 }) == Self.draws(gen))
    }

    @Test("map obeys the composition law")
    func mapComposition() {
        let gen = Gen.int(in: 0 ... 1_000)
        let f: (Int64) -> Int64 = { $0 + 1 }
        let g: (Int64) -> Int64 = { $0 * 2 }

        #expect(Self.draws(gen.map(f).map(g)) == Self.draws(gen.map { g(f($0)) }))
    }

    @Test("flatMap threads the same stream through both stages")
    func flatMapThreadsTheStream() {
        let gen = Gen.int(in: 0 ... 1_000).flatMap { first in
            Gen.int(in: 0 ... 1_000).map { second in first + second }
        }

        // Reproducing by hand: the same stream must give first then second in that order.
        var byHand = Seed(Self.seed)
        let first = Int64.random(in: 0 ... 1_000, using: &byHand)
        let second = Int64.random(in: 0 ... 1_000, using: &byHand)

        var byGen = Seed(Self.seed)
        #expect(gen.run(&byGen) == first + second)
    }

    @Test("zip pairs both values in stream order")
    func zipPairsInOrder() {
        let gen = zip(Gen.int(in: 0 ... 1_000), Gen.int(in: 0 ... 1_000))

        var byHand = Seed(Self.seed)
        let first = Int64.random(in: 0 ... 1_000, using: &byHand)
        let second = Int64.random(in: 0 ... 1_000, using: &byHand)

        var byGen = Seed(Self.seed)
        let pair = gen.run(&byGen)
        #expect(pair.0 == first)
        #expect(pair.1 == second)
    }

    @Test("array yields the requested count")
    func arrayYieldsRequestedCount() {
        let gen = Gen.int(in: 0 ... 10).array(count: .always(5))

        for array in Self.draws(gen) {
            #expect(array.count == 5)
        }
    }

    @Test("A generator is deterministic under a fixed seed")
    func generatorIsDeterministic() {
        let gen = zip3(
            Gen.int(in: -100 ... 100),
            Gen.element(of: ["a", "b", "c"]),
            Gen.int(in: 0 ... 10).array(count: .always(3))
        )

        var first = Seed(Self.seed)
        var second = Seed(Self.seed)

        for _ in 0 ..< Self.drawCount {
            let a = gen.run(&first)
            let b = gen.run(&second)
            #expect(a.0 == b.0)
            #expect(a.1 == b.1)
            #expect(a.2 == b.2)
        }
    }
}

// Turns a generator into a deterministic array for a swift-testing `arguments:` collection.
//
// The random draws are prepended with a hand-written edge corpus — the boundary values a shrinker would
// converge on, always present rather than hoped for. A single seed fixes the whole array, so a failing
// element printed by swift-testing is itself the reproduction.
func samples<Value>(
    _ generator: Gen<Value>,
    count: Int = PropertySeed.sampleCount,
    seed: UInt64,
    edges: [Value] = []
) -> [Value] {
    var stream = Seed(seed)
    var result = edges
    result.reserveCapacity(edges.count + count)

    for _ in 0 ..< count {
        result.append(generator.run(&stream))
    }

    return result
}

// A composable generator: a function from a `Seed` to one value, wrapped so it can be transformed and
// combined before it is run. Domain generators are built up from this with `map`, `flatMap` and `zip`
// rather than by ad-hoc loops, so each yields a strong domain type instead of a bare primitive.
struct Gen<Value> {
    // Takes the seed `inout` so a composed generator threads one stream through its parts in order,
    // which is what makes a whole `Case` reproducible from a single seed.
    let run: (inout Seed) -> Value
}

extension Gen {
    /// A generator that always yields `value`, drawing nothing from the stream.
    static func always(_ value: Value) -> Gen<Value> {
        Gen { _ in value }
    }

    /// Transforms each generated value.
    func map<Transformed>(_ transform: @escaping (Value) -> Transformed) -> Gen<Transformed> {
        Gen<Transformed> { seed in transform(run(&seed)) }
    }

    /// Feeds each generated value into a generator chosen from it, threading the same stream on.
    func flatMap<Transformed>(_ transform: @escaping (Value) -> Gen<Transformed>) -> Gen<Transformed> {
        Gen<Transformed> { seed in transform(run(&seed)).run(&seed) }
    }
}

extension Gen where Value == Int64 {
    /// A generator of integers drawn uniformly from `range`.
    static func int(in range: ClosedRange<Int64>) -> Gen<Int64> {
        Gen { seed in Int64.random(in: range, using: &seed) }
    }
}

extension Gen {
    /// A generator that picks one of `elements` uniformly.
    ///
    /// - Precondition: `elements` is not empty.
    static func element(of elements: [Value]) -> Gen<Value> {
        precondition(elements.isEmpty == false, "Cannot pick an element of an empty array")

        return Gen { seed in elements[Int.random(in: elements.indices, using: &seed)] }
    }
}

extension Gen {
    /// A generator of arrays, each of `count` elements drawn from this generator.
    ///
    /// - Precondition: `count` is not negative.
    func array(count: Gen<Int64>) -> Gen<[Value]> {
        Gen<[Value]> { seed in
            let length = Int(count.run(&seed))
            precondition(length >= 0, "An array cannot have a negative length")

            return (0 ..< length).map { _ in run(&seed) }
        }
    }
}

/// Combines two generators into one that yields both values, drawing `first` then `second` from the
/// stream.
func zip<A, B>(
    _ first: Gen<A>,
    _ second: Gen<B>
) -> Gen<(A, B)> {
    Gen<(A, B)> { seed in (first.run(&seed), second.run(&seed)) }
}

/// Combines three generators into one that yields all three values, in stream order.
func zip3<A, B, C>(
    _ first: Gen<A>,
    _ second: Gen<B>,
    _ third: Gen<C>
) -> Gen<(A, B, C)> {
    Gen<(A, B, C)> { seed in (first.run(&seed), second.run(&seed), third.run(&seed)) }
}

// The control for the coding benchmarks: the same journey through a coder as money takes, with no
// money work in it.
//
// A bare `String` is not a fair control. `JSONEncoder` and `JSONDecoder` have a fast path for a
// top-level fragment, so encoding a `String` skips work that any custom conformance pays. This type
// has a hand-written conformance of the same shape as money's: it asks for a single value container
// and reads or writes one string. The difference between money and this is the money work.
struct ControlAmount: Codable {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    init(from decoder: any Decoder) throws {
        text = try decoder.singleValueContainer().decode(String.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(text)
    }
}

import CLDRLocaleIdentifiers
import SwiftMoneyLocalization
import Testing

@Suite("LocaleSubtags")
struct LocaleSubtagsTests {

    /// One subtag of each shape the parsers could tell apart: empty, 1 to 9 letters, 1 to 4 digits,
    /// letters and digits mixed, and non-ASCII, including a combining mark that joins the separator
    /// before it into one `Character`.
    private static let shapes: [String] = [""]
        + (1 ... 9).map { String("abcdefghi".prefix($0)) }
        + (1 ... 4).map { String("1234".prefix($0)) }
        + ["a1", "1a", "ab1d", "Ääää", "é", "\u{301}x"]

    /// The length of BCP 47's longest language subtag, in bytes, past which the runtime chain yields
    /// the identifier alone.
    private static let longestLanguage = 8

    /// The letter case a generated name is spelled in.
    enum LetterCase: CaseIterable {
        /// As the shapes spell it.
        case lower

        /// Every letter a capital.
        case upper

        /// Returns a name spelled in this case.
        ///
        /// - Parameter name: The name, as the shapes spell it.
        /// - Returns: `name` in this case.
        func spelling(_ name: String) -> String {
            switch self {
            case .lower: name
            case .upper: name.uppercased()
            }
        }
    }

    @Test(
        "The generator reads the language, script and region the runtime chain reads",
        arguments: 1 ... 4, LetterCase.allCases
    )
    func agreesWithTheRuntimeChain(subtagCount: Int, letterCase: LetterCase) {
        let names = (0 ..< subtagCount).reduce(into: [[String]()]) { tuples, _ in
            tuples = tuples.flatMap { tuple in Self.shapes.map { tuple + [$0] } }
        }
        .map { letterCase.spelling($0.joined(separator: "-")) }

        let disagreeing = names.filter { name in
            let expected = Self.expectedChain(of: name).map(Self.bytes(of:))
            let underscored = String(
                decoding: name.utf8.map { $0 == UInt8(ascii: "-") ? UInt8(ascii: "_") : $0 },
                as: UTF8.self
            )

            return [name, underscored].contains { Self.chain(of: $0) != expected }
        }

        #expect(disagreeing.isEmpty, "\(disagreeing.count) disagree, such as \(disagreeing.prefix(5))")
    }

    /// Returns the keys the runtime chain would yield for a name, read from the generator's subtags.
    ///
    /// - Parameter name: A hyphen-separated name.
    /// - Returns: The name, then its language and script, language and region, and language, each only
    ///   when the name has more than that part; the name alone when its language is longer than 8
    ///   bytes.
    private static func expectedChain(of name: String) -> [String] {
        let subtags = LocaleSubtags(name)
        let language = String(subtags.language)
        var keys = [name]

        guard language.utf8.count <= longestLanguage else {
            return keys
        }

        if let script = subtags.script, subtags.region != nil || !subtags.rest.isEmpty {
            keys.append("\(language)-\(script)")
        }

        if let region = subtags.region, subtags.script != nil || !subtags.rest.isEmpty {
            keys.append("\(language)-\(region)")
        }

        if subtags.script != nil || subtags.region != nil || !subtags.rest.isEmpty {
            keys.append(language)
        }

        return keys
    }

    /// Returns the bytes of each key the runtime chain yields for an identifier.
    ///
    /// - Parameter identifier: The identifier to build the chain from.
    /// - Returns: Each key's folded bytes, in order.
    private static func chain(of identifier: String) -> [[UInt8]] {
        IteratorSequence(LocaleFallbackChain(LocaleIdentifier(identifier)).makeIterator()).map { key in
            Array(IteratorSequence(key.bytes.makeIterator()))
        }
    }

    /// Returns the bytes of a name read as a whole key.
    ///
    /// - Parameter name: The name to read.
    /// - Returns: The name's folded bytes.
    private static func bytes(of name: String) -> [UInt8] {
        Array(IteratorSequence(LocaleKey(LocaleIdentifier(name)).bytes.makeIterator()))
    }
}

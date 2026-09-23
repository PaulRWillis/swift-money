/// The script each language implies, from CLDR's likely-subtag data.
///
/// A locale's data has to be stored under the identifier a caller will actually ask for. ICU removes
/// a script subtag that its language already implies, so `ff-Latn-GH` reaches a formatter as `ff-GH`
/// and data filed under the longer spelling is never found. Shortening at generation time keeps both
/// spellings reachable, because the long one is canonicalised before it arrives.
///
/// This reads CLDR's own table rather than asking the platform, so the identifiers a build produces
/// depend on the pinned CLDR release and not on the ICU version of the machine running it.
public struct LikelyScripts: Equatable, Sendable {
    private let byLanguage: [String: String]

    /// - Parameter likelySubtags: CLDR's `likelySubtags` map, identifier to fully populated
    ///   identifier, as in `"ff"` to `"ff-Latn-SN"`. Entries keyed by anything but a bare language
    ///   are ignored, since only a language implies the script this removes.
    public init(likelySubtags: [String: String]) {
        byLanguage = likelySubtags.reduce(into: [:]) { scripts, entry in
            guard !entry.key.contains("-"), let script = Self.script(of: entry.value) else {
                return
            }
            scripts[entry.key] = script
        }
    }

    /// `identifier` with its script subtag removed when that script is the one its language implies.
    ///
    /// Returns the identifier unchanged when it carries no script, or one its language does not
    /// imply: `zh-Hant` keeps its script because Chinese implies `Hans`.
    public func shortened(_ identifier: String) -> String {
        let subtags = identifier.split(separator: "-", omittingEmptySubsequences: false)

        guard
            subtags.count > 1,
            Self.isScript(subtags[1]),
            byLanguage[String(subtags[0])] == String(subtags[1])
        else {
            return identifier
        }

        return ([subtags[0]] + subtags.dropFirst(2)).joined(separator: "-")
    }

    /// The script CLDR's data implies for `identifier`'s language, or nil when the language is unknown.
    ///
    /// `de-CH` implies `Latn` through `de`; `lo` implies `Laoo`. Used to decide whether a locale is
    /// written in a script a given feature covers yet.
    public func impliedScript(of identifier: String) -> String? {
        let language = identifier.split(separator: "-").first.map(String.init) ?? identifier
        return byLanguage[language]
    }

    // A fully populated identifier is language-script-region, so its script is the second subtag.
    private static func script(of identifier: String) -> String? {
        let subtags = identifier.split(separator: "-")

        guard subtags.count > 1, isScript(subtags[1]) else {
            return nil
        }

        return String(subtags[1])
    }

    // Four letters, which no language or region subtag is.
    private static func isScript(_ subtag: Substring) -> Bool {
        subtag.count == 4 && subtag.allSatisfy(\.isLetter)
    }
}

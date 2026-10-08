/// The scripts CLDR's likely subtags imply for each language, and for each language in a region.
///
/// ``shortened(_:)`` removes a script only where Unicode TR35's "Remove Likely Subtags" would, and
/// never adds or removes a region.
///
/// ```swift
/// let scripts = LikelyScripts(likelySubtags: ["zh": "zh-Hans-CN", "zh-HK": "zh-Hant-HK"])
/// scripts.shortened("zh-Hant-HK")  // "zh-HK"
/// scripts.shortened("zh-Hans-HK")  // "zh-Hans-HK"
/// ```
package struct LikelyScripts: Equatable, Hashable, Sendable {
    /// The script each bare language implies, such as `ff` to `Latn`.
    private let byLanguage: [String: String]

    /// The script each language implies in a region, keyed by language and region, such as `zh-HK`
    /// to `Hant`.
    private let byLanguageAndRegion: [String: String]

    /// Creates the table from CLDR's likely subtags.
    ///
    /// Entries keyed by a bare language or a language and region become rules. Entries keyed by `und`
    /// or by anything carrying a script are ignored, as are values with no script.
    ///
    /// ```swift
    /// LikelyScripts(likelySubtags: ["ff": "ff-Latn-SN", "sr-ME": "sr-Latn-ME"])
    /// ```
    ///
    /// - Parameter likelySubtags: CLDR's `likelySubtags` map, identifier to fully populated
    ///   identifier, as in `"ff"` to `"ff-Latn-SN"`.
    package init(likelySubtags: [String: String]) {
        var byLanguage: [String: String] = [:]
        var byLanguageAndRegion: [String: String] = [:]

        for (identifier, populated) in likelySubtags {
            let key = Subtags(identifier)

            guard
                key.language != Self.undetermined,
                key.script == nil,
                key.rest.isEmpty,
                let script = Subtags(populated).script
            else {
                continue
            }

            if let region = key.region {
                byLanguageAndRegion[Self.languageAndRegion(key.language, region)] = String(script)
            } else {
                byLanguage[String(key.language)] = String(script)
            }
        }

        self.byLanguage = byLanguage
        self.byLanguageAndRegion = byLanguageAndRegion
    }

    /// Returns an identifier with its script removed where CLDR's likely subtags imply it.
    ///
    /// The language and region's entry decides, then the language's, in TR35's lookup order. The
    /// region always stays, so `zh-Hans-CN` becomes `zh-CN` where TR35 gives `zh`.
    ///
    /// ```swift
    /// scripts.shortened("zh-Hant-HK")  // "zh-HK"
    /// scripts.shortened("zh-Hans-SG")  // "zh-SG"
    /// scripts.shortened("zh-Hant")     // "zh-Hant"
    /// ```
    ///
    /// - Parameter identifier: A hyphen-separated locale identifier in CLDR's canonical case, such
    ///   as a CLDR folder name.
    /// - Returns: `identifier` without its script, or unchanged when it carries no script or one
    ///   CLDR doesn't imply.
    package func shortened(_ identifier: String) -> String {
        let subtags = Subtags(identifier)

        guard let script = subtags.script, impliedScript(of: subtags) == String(script) else {
            return identifier
        }

        return ([subtags.language] + (subtags.region.map { [$0] } ?? []) + subtags.rest)
            .joined(separator: "-")
    }

    /// Returns the script CLDR implies for an identifier's language and region.
    ///
    /// - Parameter subtags: The identifier's subtags.
    /// - Returns: The script the language and region imply, falling back to the language's own;
    ///   `nil` when CLDR lists neither.
    private func impliedScript(of subtags: Subtags) -> String? {
        let regional = subtags.region.flatMap {
            byLanguageAndRegion[Self.languageAndRegion(subtags.language, $0)]
        }

        return regional ?? byLanguage[String(subtags.language)]
    }

    /// The language subtag CLDR uses for "undetermined", whose entries name no language of their own.
    private static let undetermined: Substring = "und"

    /// Returns the key a language and region are looked up by.
    ///
    /// - Parameters:
    ///   - language: The language subtag.
    ///   - region: The region subtag.
    /// - Returns: The two joined by a hyphen, as in `zh-HK`.
    private static func languageAndRegion(_ language: Substring, _ region: Substring) -> String {
        "\(language)-\(region)"
    }
}

extension LikelyScripts {
    /// A locale identifier split into its language, script, region and any subtags after those.
    ///
    /// A subtag counts as a script or a region only in its own position and shape, so `es-419` has a
    /// region and no script, and `ca-ES-valencia` keeps `valencia` in ``rest``.
    private struct Subtags: Sendable, Equatable, Hashable {
        /// The first subtag.
        let language: Substring

        /// The four-letter script after the language, if there is one.
        let script: Substring?

        /// The region after the language and any script, if there is one.
        let region: Substring?

        /// Every subtag after the language, script and region, in order.
        let rest: [Substring]

        /// Splits an identifier into its subtags.
        ///
        /// - Parameter identifier: A hyphen-separated locale identifier.
        init(_ identifier: String) {
            language = identifier.prefix { $0 != "-" }

            var remaining = identifier.split(separator: "-", omittingEmptySubsequences: false)
                .dropFirst()

            if let next = remaining.first, Self.isScript(next) {
                script = next
                remaining = remaining.dropFirst()
            } else {
                script = nil
            }

            if let next = remaining.first, Self.isRegion(next) {
                region = next
                remaining = remaining.dropFirst()
            } else {
                region = nil
            }

            rest = Array(remaining)
        }

        /// The length of a script subtag, such as `Latn`.
        private static let scriptLength = 4

        /// The length of a letter region subtag, such as `GB`.
        private static let letterRegionLength = 2

        /// The length of a numeric region subtag, such as `419`.
        private static let numericRegionLength = 3

        /// Returns whether a subtag has a script's shape: four ASCII letters.
        ///
        /// - Parameter subtag: The subtag to check.
        /// - Returns: `true` if `subtag` is four ASCII letters; otherwise, `false`.
        private static func isScript(_ subtag: Substring) -> Bool {
            subtag.count == scriptLength && subtag.allSatisfy { $0.isASCII && $0.isLetter }
        }

        /// Returns whether a subtag has a region's shape: two uppercase letters or three digits.
        ///
        /// - Parameter subtag: The subtag to check.
        /// - Returns: `true` if `subtag` is a region code; otherwise, `false`.
        private static func isRegion(_ subtag: Substring) -> Bool {
            switch subtag.count {
            case letterRegionLength:
                subtag.allSatisfy { $0.isASCII && $0.isUppercase }
            case numericRegionLength:
                subtag.allSatisfy { $0.isASCII && $0.isNumber }
            default:
                false
            }
        }
    }
}

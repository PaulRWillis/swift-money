/// The scripts CLDR's likely subtags imply for each language, and for each language in a region.
///
/// ``shortened(_:)`` removes a script only where Unicode TR35's "Remove Likely Subtags" would, and
/// ``withImpliedScript(_:)`` inserts one only where the name has none. Neither adds or removes a
/// region.
///
/// ```swift
/// let scripts = LikelyScripts(likelySubtags: ["zh": "zh-Hans-CN", "zh-HK": "zh-Hant-HK"])
/// scripts.shortened("zh-Hant-HK")    // "zh-HK"
/// scripts.shortened("zh-Hans-HK")    // "zh-Hans-HK"
/// scripts.withImpliedScript("zh-HK")  // "zh-Hant-HK"
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
            let key = LocaleSubtags(identifier)

            guard
                key.language != Self.undetermined,
                key.script == nil,
                key.rest.isEmpty,
                let script = LocaleSubtags(populated).script
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
        let subtags = LocaleSubtags(identifier)

        guard let script = subtags.script, impliedScript(of: subtags) == String(script) else {
            return identifier
        }

        return LocaleSubtags(language: subtags.language, script: nil, region: subtags.region, rest: subtags.rest)
            .name
    }

    /// Returns an identifier with the script CLDR implies inserted where it has none.
    ///
    /// The language and region's entry decides, then the language's. No region is added, so this
    /// isn't TR35's "Add Likely Subtags".
    ///
    /// ```swift
    /// scripts.withImpliedScript("zh-TW")       // "zh-Hant-TW"
    /// scripts.withImpliedScript("zh")          // "zh-Hans"
    /// scripts.withImpliedScript("zh-Hans-TW")  // "zh-Hans-TW"
    /// ```
    ///
    /// - Parameter identifier: A hyphen-separated locale identifier in CLDR's canonical case.
    /// - Returns: `identifier` with its implied script after the language, or unchanged when it
    ///   already carries a script or CLDR implies none.
    package func withImpliedScript(_ identifier: String) -> String {
        let subtags = LocaleSubtags(identifier)

        guard subtags.script == nil, let script = impliedScript(of: subtags) else {
            return identifier
        }

        return LocaleSubtags(
            language: subtags.language, script: Substring(script), region: subtags.region, rest: subtags.rest
        ).name
    }

    /// Returns the script CLDR implies for an identifier's language and region.
    ///
    /// - Parameter subtags: The identifier's subtags.
    /// - Returns: The script the language and region imply, falling back to the language's own;
    ///   `nil` when CLDR lists neither.
    private func impliedScript(of subtags: LocaleSubtags) -> String? {
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

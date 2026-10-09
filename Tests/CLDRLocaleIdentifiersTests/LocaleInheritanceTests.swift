import CLDRLocaleIdentifiers
import Testing

@Suite("LocaleInheritance")
struct LocaleInheritanceTests {

    /// Real CLDR 48.2 folder names for the languages these tests resolve.
    private static let folders = [
        "und", "en", "en-IN", "es", "es-419", "hi", "hi-Latn", "ku",
        "zh", "zh-Hans", "zh-Hant", "zh-Hant-HK", "zh-Hant-MO",
    ]

    /// Real CLDR 48.2 likely-subtag entries for the same languages.
    private static let likelySubtags = [
        "en": "en-Latn-US",
        "es": "es-Latn-ES",
        "hi": "hi-Deva-IN",
        "ku": "ku-Latn-TR",
        "ku-AM": "ku-Cyrl-AM",
        "ku-Cyrl": "ku-Cyrl-AM",
        "zh": "zh-Hans-CN",
        "zh-HK": "zh-Hant-HK",
        "zh-Hant": "zh-Hant-TW",
        "zh-MO": "zh-Hant-MO",
        "zh-TW": "zh-Hant-TW",
    ]

    /// Real CLDR 48.2 parent locales for the same languages.
    private static let parentLocales = [
        "es-JP": "es-419",
        "hi-Latn": "en-IN",
        "ku-Cyrl": "und",
        "zh-Hant": "und",
        "zh-Hant-MO": "zh-Hant-HK",
    ]

    /// Returns the inheritance the fixtures above describe, with some folders left out.
    ///
    /// - Parameter missing: The folders to leave out.
    /// - Returns: The inheritance over the remaining folders.
    /// - Throws: An issue when the fixtures don't build.
    private static func inheritance(without missing: Set<String> = []) throws -> LocaleInheritance {
        try LocaleInheritance(
            folders: folders.filter { !missing.contains($0) },
            likelySubtags: likelySubtags,
            parentLocales: parentLocales
        )
    }

    @Test(
        "A name reaches the locale TR35's lookup gives it",
        arguments: [
            ("zh-TW", "zh-Hant"),
            ("zh-Hans-TW", "zh"),
            ("hi-Latn-IN", "hi-Latn"),
            ("es-JP", "es-419"),
            ("ku-AM", "und"),
            ("ku-Cyrl", "und"),
            ("en-GB", "en"),
            ("xx", "und"),
        ]
    )
    func reachedLocale(_ name: String, _ expected: String) throws {
        #expect(try Self.inheritance().group(reachedFrom: name).shortName == expected)
    }

    // `hi-Latn` names a parent too, but a folder is found before any parent is followed.
    @Test("A name with a folder reaches its own group")
    func folderReachesItsOwnGroup() throws {
        let inheritance = try Self.inheritance()

        #expect(inheritance.group(reachedFrom: "hi-Latn").shortName == "hi-Latn")
        #expect(inheritance.group(reachedFrom: "zh-Hant-MO").shortName == "zh-MO")
        #expect(inheritance.group(reachedFrom: "zh-MO").shortName == "zh-MO")
    }

    // CLDR keys this parent by `zh-Hant-MO`, so `zh-MO` finds it only through its implied script.
    @Test("A parent keyed by the spelling with the implied script is followed")
    func parentKeyedByImpliedSpelling() throws {
        let inheritance = try Self.inheritance(without: ["zh-Hant-MO"])

        #expect(inheritance.group(reachedFrom: "zh-MO").shortName == "zh-HK")
        #expect(inheritance.group(reachedFrom: "zh-Hant-MO").shortName == "zh-HK")
    }

    // Dropping the region first would reach `en` through `en-Latn`.
    @Test("A variant is dropped before the region")
    func variantDroppedFirst() throws {
        #expect(try Self.inheritance().group(reachedFrom: "en-IN-oxendict").shortName == "en-IN")
    }

    @Test("A group is found by any of its names, and only those")
    func groupByName() throws {
        let inheritance = try Self.inheritance()

        #expect(inheritance.group(named: "zh-Hant-HK")?.shortName == "zh-HK")
        #expect(inheritance.group(named: "zh-HK")?.shortName == "zh-HK")
        #expect(inheritance.group(named: "zh-TW") == nil)
    }

    @Test("Folders without a root folder are refused")
    func noRoot() {
        #expect(throws: LocaleInheritance.InheritanceError.noRoot) {
            try Self.inheritance(without: ["und"])
        }
    }

    @Test("Two parents naming each other are refused")
    func parentsInALoop() {
        #expect(throws: LocaleInheritance.InheritanceError.cycle(through: "xx-AA")) {
            try LocaleInheritance(
                folders: ["und", "xx"],
                likelySubtags: [:],
                parentLocales: ["xx-AA": "xx-BB", "xx-BB": "xx-AA"]
            )
        }
    }

    // `xx-Latn-AA` truncates back to `xx-Latn`, whose parent is `xx-Latn-AA`.
    @Test("A parent that truncation leads back to is refused")
    func parentAndTruncationInALoop() {
        #expect(throws: LocaleInheritance.InheritanceError.cycle(through: "xx-Latn")) {
            try LocaleInheritance(
                folders: ["und", "xx"],
                likelySubtags: [:],
                parentLocales: ["xx-Latn": "xx-Latn-AA"]
            )
        }
    }
}

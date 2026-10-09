import CLDRLocaleIdentifiers
import Testing

@Suite("ResolvedNames")
struct ResolvedNamesTests {

    /// Real CLDR 48.2 folder names for the languages these tests file names in.
    private static let folders = [
        "und", "ha", "ha-Arab", "ha-Arab-SD", "ha-GH", "ku", "pa-Arab", "pa-Guru", "ug",
        "zh", "zh-Hans", "zh-Hant",
    ]

    /// Real CLDR 48.2 likely-subtag entries for the same languages.
    private static let likelySubtags = [
        "ha": "ha-Latn-NG",
        "ha-CM": "ha-Arab-CM",
        "ha-SD": "ha-Arab-SD",
        "ku": "ku-Latn-TR",
        "ku-AM": "ku-Cyrl-AM",
        "ku-Cyrl": "ku-Cyrl-AM",
        "pa": "pa-Guru-IN",
        "pa-PK": "pa-Arab-PK",
        "ug": "ug-Arab-CN",
        "ug-Cyrl": "ug-Cyrl-KZ",
        "ug-KZ": "ug-Cyrl-KZ",
        "zh": "zh-Hans-CN",
        "zh-Hant": "zh-Hant-TW",
        "zh-TW": "zh-Hant-TW",
    ]

    /// Real CLDR 48.2 parent locales for the same languages.
    private static let parentLocales = [
        "ha-Arab": "und",
        "ku-Cyrl": "und",
        "pa-Arab": "und",
        "ug-Cyrl": "und",
        "zh-Hant": "und",
    ]

    /// Returns the inheritance the fixtures describe, and every group but Gurmukhi Punjabi built, each
    /// valued at its short name.
    ///
    /// - Returns: The inheritance and the built locales.
    /// - Throws: An issue when the fixtures don't build.
    private static func fixture() throws -> (LocaleInheritance, [BuiltLocale<String>]) {
        let inheritance = try LocaleInheritance(
            folders: folders, likelySubtags: likelySubtags, parentLocales: parentLocales
        )
        let built = inheritance.groups
            .filter { $0.shortName != "pa" }
            .map { BuiltLocale(group: $0, value: $0.shortName) }

        return (inheritance, built)
    }

    /// Returns each filed name with the short name of the locale it reaches.
    ///
    /// - Returns: The filed names and their locales, in the order filed.
    /// - Throws: An issue when the fixtures don't build.
    private static func filed() throws -> [(name: String, locale: String)] {
        let (inheritance, built) = try fixture()

        return inheritance.resolvedNames(for: built).map { ($0.name, $0.locale.value) }
    }

    @Test("Each name is filed under the locale TR35 reaches, in the order the runtime searches")
    func filedNames() throws {
        let filed = try Self.filed()

        #expect(filed.map(\.name) == [
            "ha-CM", "ha-Latn", "ha-Latn-GH", "ku-AM", "ku-Latn", "pa-PK", "ug-Arab", "ug-KZ", "zh-TW",
        ])
        #expect(filed.map(\.locale) == ["ha-Arab", "ha", "ha-GH", "und", "ku", "pa-Arab", "ug", "und", "zh-Hant"])
    }

    // `zh-Hant-TW` reaches `zh-Hant` through the chain, but only if `zh-hant` matches the key
    // spelled `zh-Hant`.
    @Test("A spelling the chain already reaches is not filed")
    func reachedSpellingIsNotFiled() throws {
        let names = try Self.filed().map(\.name)

        #expect(!names.contains("zh-Hant-TW"))
        #expect(!names.contains("ug-Cyrl-KZ"))
        #expect(!names.contains("ku-Cyrl-AM"))
    }

    @Test("A place whose locale wasn't built is not filed, and is reported")
    func unbuiltTargetIsReported() throws {
        let (inheritance, built) = try Self.fixture()

        #expect(!inheritance.resolvedNames(for: built).map(\.name).contains("pa-IN"))
        #expect(inheritance.placesReachingUnbuiltLocales(for: built) == ["pa-IN"])
    }

    @Test("Nothing built, nothing filed")
    func nothingBuilt() throws {
        let (inheritance, _) = try Self.fixture()

        #expect(inheritance.resolvedNames(for: [BuiltLocale<String>]()).isEmpty)
    }
}

import CLDRLocaleIdentifiers
import Testing

@Suite("LikelyScripts")
struct LikelyScriptsTests {

    // Real CLDR 48.2 entries for the languages whose identifiers this actually changes.
    private static let scripts = LikelyScripts(likelySubtags: [
        "ff": "ff-Latn-SN",
        "az": "az-Latn-AZ",
        "sr": "sr-Cyrl-RS",
        "zh": "zh-Hans-CN",
        "en": "en-Latn-US",
        "ff-Arab": "ff-Arab-NG",
    ])

    @Test("A script its language implies is removed")
    func impliedScriptIsRemoved() {
        #expect(Self.scripts.shortened("ff-Latn") == "ff")
        #expect(Self.scripts.shortened("az-Latn") == "az")
        #expect(Self.scripts.shortened("sr-Cyrl") == "sr")
    }

    // The case that started this: ICU turns ff-Latn-GH into ff-GH, so data under the long spelling
    // is unreachable.
    @Test("A region after the implied script is kept")
    func regionSurvives() {
        #expect(Self.scripts.shortened("ff-Latn-GH") == "ff-GH")
        #expect(Self.scripts.shortened("sr-Cyrl-ME") == "sr-ME")
    }

    @Test("A script its language does not imply is kept")
    func unimpliedScriptIsKept() {
        #expect(Self.scripts.shortened("zh-Hant") == "zh-Hant")
        #expect(Self.scripts.shortened("zh-Hant-TW") == "zh-Hant-TW")
        #expect(Self.scripts.shortened("ff-Adlm") == "ff-Adlm")
    }

    @Test("An identifier with no script is unchanged")
    func noScriptIsUnchanged() {
        #expect(Self.scripts.shortened("en") == "en")
        #expect(Self.scripts.shortened("en-GB") == "en-GB")
        #expect(Self.scripts.shortened("es-419") == "es-419")
    }

    @Test("A language the table does not list is unchanged")
    func unknownLanguageIsUnchanged() {
        #expect(Self.scripts.shortened("xyz-Latn") == "xyz-Latn")
    }

    // Only a bare language implies a script, so an entry keyed by more than one subtag must not
    // become a rule: ff-Arab implies Arab, but that says nothing about plain ff.
    @Test("Only a bare language contributes a rule")
    func onlyLanguageKeysCount() {
        #expect(Self.scripts.shortened("ff-Arab") == "ff-Arab")
    }

    @Test("An empty table changes nothing")
    func emptyTableIsIdentity() {
        #expect(LikelyScripts(likelySubtags: [:]).shortened("ff-Latn-GH") == "ff-Latn-GH")
    }

    // A value with no script cannot say what a language implies, and must not crash or half-apply.
    @Test("A likely subtag with no script contributes no rule")
    func scriptlessValueIsIgnored() {
        #expect(LikelyScripts(likelySubtags: ["ff": "ff"]).shortened("ff-Latn") == "ff-Latn")
    }
}

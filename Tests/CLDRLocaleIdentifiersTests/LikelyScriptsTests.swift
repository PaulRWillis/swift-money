import CLDRLocaleIdentifiers
import Testing

@Suite("LikelyScripts")
struct LikelyScriptsTests {

    /// Real CLDR 48.2 likely-subtag entries for the languages whose names this changes.
    private static let scripts = LikelyScripts(likelySubtags: [
        "az": "az-Latn-AZ",
        "az-Arab": "az-Arab-IR",
        "az-IQ": "az-Arab-IQ",
        "en": "en-Latn-US",
        "ff": "ff-Latn-SN",
        "ha": "ha-Latn-NG",
        "ha-SD": "ha-Arab-SD",
        "ku": "ku-Latn-TR",
        "ku-IQ": "ku-Arab-IQ",
        "ku-IR": "ku-Arab-IR",
        "sr": "sr-Cyrl-RS",
        "sr-ME": "sr-Latn-ME",
        "und-HK": "zh-Hant-HK",
        "und-Arab-AZ": "az-Arab-AZ",
        "yue": "yue-Hant-HK",
        "yue-CN": "yue-Hans-CN",
        "zh": "zh-Hans-CN",
        "zh-HK": "zh-Hant-HK",
        "zh-Hant": "zh-Hant-TW",
        "zh-MO": "zh-Hant-MO",
    ])

    @Test("A script its language implies is removed")
    func impliedScriptIsRemoved() {
        #expect(Self.scripts.shortened("ff-Latn") == "ff")
        #expect(Self.scripts.shortened("az-Latn") == "az")
        #expect(Self.scripts.shortened("sr-Cyrl") == "sr")
    }

    @Test("A script its language and region imply is removed")
    func scriptImpliedByRegionIsRemoved() {
        #expect(Self.scripts.shortened("zh-Hant-HK") == "zh-HK")
        #expect(Self.scripts.shortened("zh-Hant-MO") == "zh-MO")
        #expect(Self.scripts.shortened("sr-Latn-ME") == "sr-ME")
        #expect(Self.scripts.shortened("ku-Arab-IR") == "ku-IR")
        #expect(Self.scripts.shortened("az-Arab-IQ") == "az-IQ")
        #expect(Self.scripts.shortened("ha-Arab-SD") == "ha-SD")
    }

    // The language alone implies these scripts, but the region implies another, so the short name
    // belongs to the other script's folder.
    @Test("A script its language implies but its region does not is kept")
    func scriptTheRegionOverridesIsKept() {
        #expect(Self.scripts.shortened("zh-Hans-HK") == "zh-Hans-HK")
        #expect(Self.scripts.shortened("zh-Hans-MO") == "zh-Hans-MO")
        #expect(Self.scripts.shortened("sr-Cyrl-ME") == "sr-Cyrl-ME")
        #expect(Self.scripts.shortened("yue-Hant-CN") == "yue-Hant-CN")
        #expect(Self.scripts.shortened("ku-Latn-IQ") == "ku-Latn-IQ")
    }

    @Test("A region with no entry of its own falls back to the language's script")
    func regionWithoutEntryFallsBackToLanguage() {
        #expect(Self.scripts.shortened("ff-Latn-GH") == "ff-GH")
        #expect(Self.scripts.shortened("zh-Hans-SG") == "zh-SG")
        #expect(Self.scripts.shortened("ku-Latn-SY") == "ku-SY")
    }

    // `sr-ME` implies Latin, but `sr-Latn` names no region, so only the language's own script counts.
    @Test("A script with no region is judged by the language alone")
    func scriptWithoutRegionIgnoresRegionalRules() {
        #expect(Self.scripts.shortened("sr-Latn") == "sr-Latn")
        #expect(Self.scripts.shortened("az-Arab") == "az-Arab")
    }

    @Test("A script neither the language nor the region implies is kept")
    func unimpliedScriptIsKept() {
        #expect(Self.scripts.shortened("zh-Hant") == "zh-Hant")
        #expect(Self.scripts.shortened("zh-Hant-TW") == "zh-Hant-TW")
        #expect(Self.scripts.shortened("zh-Hant-MY") == "zh-Hant-MY")
        #expect(Self.scripts.shortened("ff-Adlm") == "ff-Adlm")
    }

    @Test("An identifier with no script is unchanged")
    func noScriptIsUnchanged() {
        #expect(Self.scripts.shortened("en") == "en")
        #expect(Self.scripts.shortened("en-GB") == "en-GB")
        #expect(Self.scripts.shortened("es-419") == "es-419")
        #expect(Self.scripts.shortened("ca-ES-valencia") == "ca-ES-valencia")
    }

    @Test("Subtags after the region are kept")
    func subtagsAfterTheRegionSurvive() {
        #expect(Self.scripts.shortened("sr-Latn-ME-variant") == "sr-ME-variant")
        #expect(Self.scripts.shortened("ff-Latn-GH-variant") == "ff-GH-variant")
    }

    @Test("A language the table does not list is unchanged")
    func unknownLanguageIsUnchanged() {
        #expect(Self.scripts.shortened("xyz-Latn") == "xyz-Latn")
        #expect(Self.scripts.shortened("xyz-Latn-GB") == "xyz-Latn-GB")
    }

    // `zh-Hant` implies Taiwan, which says nothing about which script plain `zh` implies, and an
    // entry keyed by `und` names no language at all.
    @Test("Entries keyed by a script or by und add no rule")
    func scriptAndUndKeysAddNoRule() {
        let scripts = LikelyScripts(likelySubtags: [
            "zh-Hant": "zh-Hant-TW",
            "und-HK": "zh-Hant-HK",
            "und-Hant": "zh-Hant-TW",
        ])

        #expect(scripts.shortened("zh-Hant") == "zh-Hant")
        #expect(scripts.shortened("zh-Hant-TW") == "zh-Hant-TW")
        #expect(scripts.shortened("zh-Hant-HK") == "zh-Hant-HK")
        #expect(scripts.shortened("und-Hant-HK") == "und-Hant-HK")
    }

    @Test("Four letters outside ASCII are not read as a script")
    func nonASCIILettersAreNoScript() {
        let scripts = LikelyScripts(likelySubtags: ["xx": "xx-Ääää-ZZ"])

        #expect(scripts.shortened("xx-Ääää") == "xx-Ääää")
    }

    @Test("The script a language and region imply is inserted")
    func impliedScriptIsInserted() {
        let scripts = LikelyScripts(likelySubtags: ["zh": "zh-Hans-CN", "zh-TW": "zh-Hant-TW"])

        #expect(scripts.withImpliedScript("zh-TW") == "zh-Hant-TW")
        #expect(scripts.withImpliedScript("zh") == "zh-Hans")
        #expect(scripts.withImpliedScript("zh-SG") == "zh-Hans-SG")
    }

    @Test("A name with a script, or a language the table doesn't list, keeps its spelling")
    func impliedScriptLeavesOthersAlone() {
        let scripts = LikelyScripts(likelySubtags: ["zh": "zh-Hans-CN", "zh-TW": "zh-Hant-TW"])

        #expect(scripts.withImpliedScript("zh-Hant-TW") == "zh-Hant-TW")
        #expect(scripts.withImpliedScript("zh-Hans-TW") == "zh-Hans-TW")
        #expect(scripts.withImpliedScript("xx") == "xx")
        #expect(scripts.withImpliedScript("xx-GB") == "xx-GB")
    }

    @Test("Subtags after the region stay after it when a script is inserted")
    func impliedScriptKeepsTheRest() {
        let scripts = LikelyScripts(likelySubtags: ["ca": "ca-Latn-ES"])

        #expect(scripts.withImpliedScript("ca-ES-valencia") == "ca-Latn-ES-valencia")
    }

    @Test("An empty table changes nothing")
    func emptyTableIsIdentity() {
        #expect(LikelyScripts(likelySubtags: [:]).shortened("ff-Latn-GH") == "ff-Latn-GH")
    }

    // A value with no script cannot say what a language implies, and must not crash or half-apply.
    @Test("A likely subtag with no script contributes no rule")
    func scriptlessValueIsIgnored() {
        #expect(LikelyScripts(likelySubtags: ["ff": "ff"]).shortened("ff-Latn") == "ff-Latn")
        #expect(LikelyScripts(likelySubtags: ["sr-ME": "sr-ME"]).shortened("sr-Latn-ME") == "sr-Latn-ME")
    }
}

import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Locale Name Tests")
struct MoneyFormatStyleLocaleNameTests {
    private typealias BAM = MoneyOf<Currencies.BAM>
    private typealias TWD = MoneyOf<Currencies.TWD>

    @Test("Hong Kong Chinese writes the yen as ¥ under both of its names", arguments: ["zh_HK", "zh-Hant-HK"])
    func hongKongChineseYen(_ identifier: String) {
        let style = JPY.FormatStyle().locale(Locale(identifier: identifier))

        #expect(style.format(JPY(minorUnits: 1)) == "¥1")
    }

#if canImport(Darwin)
    // Apple's `Locale` rewrites this identifier to `sr_ME` before the style reads it, and CLDR says
    // `sr-ME` is written in Latin. Linux keeps the spelling and falls back to Cyrillic `sr`.
    @Test("A Locale named Cyrillic Serbian in Montenegro writes the convertible mark in Latin")
    func cyrillicMontenegrinSerbianLocale() {
        let style = BAM.FormatStyle().locale(Locale(identifier: "sr-Cyrl-ME"))

        #expect(style.format(BAM(minorUnits: 1_00)).contains("KM"))
    }
#endif

    @Test("A Locale for Taiwan writes the New Taiwan dollar as $")
    func taiwaneseChineseDollar() {
        let style = TWD.FormatStyle().locale(Locale(identifier: "zh_TW"))

        #expect(style.format(TWD(minorUnits: 1_234_56)) == "$1,234.56")
    }

    // Apple's `Locale` drops a script it takes as the region's default, so this reaches the style as
    // `sr-RO`, which CLDR writes in Latin. A `Locale` that keeps the script asked for Cyrillic.
    @Test("A Locale named Cyrillic Serbian in Romania writes Latin under the region's name, Cyrillic under its own")
    func cyrillicRomanianSerbianLocale() {
        let locale = Locale(identifier: "sr-Cyrl-RO")
        let written = USD.FormatStyle().locale(locale).presentation(.fullName).format(USD(minorUnits: 1_234_56))

        switch locale.identifier {
        case "sr-RO":
            #expect(written.contains("dolara"), "\(written)")
        case "sr-Cyrl-RO":
            #expect(written.contains("долара"), "\(written)")
        default:
            Issue.record("Foundation spells sr-Cyrl-RO as \(locale.identifier)")
        }
    }

    @Test("A Locale built from Serbian, Cyrillic and Romania writes Cyrillic")
    func cyrillicRomanianSerbianComponents() {
        let components = Locale.Components(languageCode: "sr", script: "Cyrl", languageRegion: "RO")
        let style = USD.FormatStyle().locale(Locale(components: components)).presentation(.fullName)

        #expect(style.format(USD(minorUnits: 1_234_56)).contains("долара"))
    }

    // What the style reads: Apple fixes case and drops a script it takes as the region's default;
    // swift-foundation passes the identifier through as written.
    @Test(
        "A Locale passes on the identifier Foundation spells for it",
        arguments: [
            ("sr-Cyrl-RO", "sr-RO"), ("az-Latn-IR", "az-IR"), ("az-Latn-RU", "az-RU"), ("ha-Latn-CM", "ha-CM"),
            ("kk-Cyrl-AF", "kk-AF"), ("kk-Cyrl-CN", "kk-CN"), ("kk-Cyrl-IR", "kk-IR"), ("kk-Cyrl-MN", "kk-MN"),
            ("ky-Cyrl-CN", "ky-CN"), ("ky-Cyrl-TR", "ky-TR"), ("mn-Cyrl-CN", "mn-CN"), ("ms-Latn-CC", "ms-CC"),
            ("sr-Cyrl-TR", "sr-TR"), ("tg-Cyrl-PK", "tg-PK"), ("ZH_tw", "zh_TW"), ("EN_gb", "en_GB"),
            ("SR-latn-rs", "sr-Latn-RS"),
        ]
    )
    func identifierFoundationPassesOn(_ input: String, _ apple: String) {
#if canImport(Darwin)
        #expect(Locale(identifier: input).identifier == apple)
#else
        #expect(Locale(identifier: input).identifier == input)
#endif
    }
}

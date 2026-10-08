import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Locale Name Tests")
struct MoneyFormatStyleLocaleNameTests {
    private typealias BAM = MoneyOf<Currencies.BAM>

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
}

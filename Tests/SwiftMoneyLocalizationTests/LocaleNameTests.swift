import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// CLDR names a locale two ways: its folder name, and a short name that drops the script where the
// language and region imply it. These pin which locale's data each name reaches.
@Suite("Locale Name Tests")
struct LocaleNameTests {

    /// Returns an amount as a locale writes it in standard presentation.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount in the currency's minor units.
    ///   - code: The currency's ISO code.
    ///   - locale: The locale to write it in.
    /// - Returns: The formatted amount.
    /// - Throws: An issue when the locale isn't covered or the code isn't a shipped currency.
    private static func formatted(
        _ minorUnits: Int64,
        _ code: CurrencyCode,
        in locale: LocaleIdentifier
    ) throws -> String {
        let currency = try #require(Currency(iso: code))
        let format = try #require(MoneyLocalization.moneyFormat(for: currency, locale: locale))

        return format.format(Money(minorUnits: minorUnits, currency: currency))
    }

    @Test(
        "Hong Kong Chinese writes the yen as ¥ under both of its names",
        arguments: ["zh-HK", "zh_HK", "zh-Hant-HK"] as [LocaleIdentifier]
    )
    func hongKongChineseYen(_ locale: LocaleIdentifier) throws {
        #expect(try Self.formatted(1, "JPY", in: locale) == "¥1")
    }

    // Plain `zh` writes the yuan as `¥`, so `CN¥` shows the folder's own data is reached.
    @Test("Simplified Chinese in Hong Kong writes the yuan as CN¥ from its own data")
    func simplifiedHongKongChineseYuan() throws {
        #expect(try Self.formatted(1_00, "CNY", in: "zh-Hans-HK").hasPrefix("CN¥"))
    }

    // A pin: plain `zh` also writes `JP¥`, so this passes whichever folder's data is reached.
    @Test("Simplified Chinese in Hong Kong writes the yen as JP¥")
    func simplifiedHongKongChineseYen() throws {
        #expect(try Self.formatted(1, "JPY", in: "zh-Hans-HK") == "JP¥1")
    }

    @Test("Singapore Chinese writes the yuan as CN¥ under its long name")
    func singaporeChineseYuan() throws {
        #expect(try Self.formatted(1_00, "CNY", in: "zh-Hans-SG").hasPrefix("CN¥"))
    }

    @Test(
        "Montenegrin Serbian writes the convertible mark in Latin under both of its names",
        arguments: ["sr-ME", "sr_ME", "sr-Latn-ME"] as [LocaleIdentifier]
    )
    func montenegrinSerbianMark(_ locale: LocaleIdentifier) throws {
        #expect(try Self.formatted(1_00, "BAM", in: locale).contains("KM"))
    }

    // CLDR says `sr-ME` is Latin, so the Cyrillic folder has no short name; asked for directly, it
    // reaches plain Serbian, which is Cyrillic.
    @Test("Cyrillic Serbian in Montenegro falls back to Serbian")
    func cyrillicMontenegrinSerbianFallsBack() throws {
        let cyrillic = try Self.formatted(1_00, "BAM", in: "sr-Cyrl-ME")

        #expect(cyrillic == (try Self.formatted(1_00, "BAM", in: "sr")))
        #expect(cyrillic.contains("КМ"))
    }

    /// Returns an amount as a locale writes it with the currency named in full.
    ///
    /// - Parameters:
    ///   - minorUnits: The amount in the currency's minor units.
    ///   - code: The currency's ISO code.
    ///   - locale: The locale to write it in.
    /// - Returns: The formatted amount.
    /// - Throws: An issue when the locale isn't covered, CLDR doesn't name the currency there, or the
    ///   code isn't a shipped currency.
    private static func fullName(
        _ minorUnits: Int64,
        _ code: CurrencyCode,
        in locale: LocaleIdentifier
    ) throws -> String {
        let currency = try #require(Currency(iso: code))
        let format = try #require(
            MoneyLocalization.fullNameMoneyFormat(for: currency, minorUnits: minorUnits, locale: locale)
        )

        return format.format(Money(minorUnits: minorUnits, currency: currency))
    }

    @Test("An identifier in another letter case reaches the same locale")
    func letterCaseReachesTheSameLocale() {
        let locales = MoneyLocalization.cldr.locales

        #expect(locales.index(of: "EN_gb") == locales.index(of: "en-GB"))
        #expect(locales.index(of: "EN_gb") != nil)
    }

    // English names one whole króna in the singular, so the singular shows the plural rules come
    // from the locale found rather than from the identifier's spelling of its language.
    @Test("An identifier in another letter case names a currency with its locale's plural rules")
    func letterCaseKeepsThePluralRules() throws {
        #expect(try Self.fullName(1_00, "USD", in: "EN_gb") == "1.00 US dollars")
        #expect(try Self.fullName(1, "ISK", in: "EN_gb") == "1 Icelandic króna")
    }

    @Test("Every covered locale has plural rules")
    func everyLocaleHasPluralRules() {
        let operands = PluralOperandValues(minorUnits: 1, unitScale: Currency.jpy.unitScale)

        for position in 0 ..< MoneyLocalization.cldr.locales.localeCount {
            let index = LocaleIndex(position: position)

            #expect(MoneyLocalization.pluralCategory(of: operands, at: index) != nil, "\(position)")
        }
    }

    // The Arabic-script folder writes a decimal point where plain Azerbaijani writes a comma.
    @Test("Iraqi Azerbaijani reaches the Arabic-script data, not plain Azerbaijani")
    func iraqiAzerbaijani() throws {
        let short = try Self.formatted(12_34, "USD", in: "az_IQ")

        #expect(short == (try Self.formatted(12_34, "USD", in: "az-Arab-IQ")))
        #expect(short != (try Self.formatted(12_34, "USD", in: "az")))
    }

    /// Returns how a locale writes 1,234.56 in a few currencies, in each presentation and in full.
    ///
    /// An entry is `nil` where the locale isn't covered or CLDR doesn't name the currency there.
    ///
    /// - Parameter locale: The locale to write in.
    /// - Returns: Every rendering, in a fixed order of currency and presentation.
    /// - Throws: An issue when a code isn't a shipped currency.
    private static func renderings(in locale: LocaleIdentifier) throws -> [String?] {
        let codes: [CurrencyCode] = ["USD", "EUR", "JPY", "CNY", "TWD", "GHS", "SGD", "RON"]
        let presentations: [CurrencyPresentation] = [.standard, .narrow, .isoCode]

        return try codes.flatMap { code -> [String?] in
            let currency = try #require(Currency(iso: code))
            let money = Money(minorUnits: 1_234_56, currency: currency)
            let short = presentations.map {
                MoneyLocalization.moneyFormat(for: currency, locale: locale, presentation: $0)
            }
            let full = MoneyLocalization.fullNameMoneyFormat(for: currency, minorUnits: 1_234_56, locale: locale)

            return (short + [full]).map { $0?.format(money) }
        }
    }

    /// Every place CLDR names with no folder of its own that the tables file, with the locale CLDR's
    /// lookup reaches from it.
    static let placesWithNoFolder: [(name: LocaleIdentifier, target: LocaleIdentifier)] = [
        ("zh-AU", "zh-Hant"), ("zh-BN", "zh-Hant"), ("zh-GB", "zh-Hant"), ("zh-GF", "zh-Hant"),
        ("zh-ID", "zh-Hant"), ("zh-PA", "zh-Hant"), ("zh-PF", "zh-Hant"), ("zh-PH", "zh-Hant"),
        ("zh-SR", "zh-Hant"), ("zh-TH", "zh-Hant"), ("zh-TW", "zh-Hant"), ("zh-US", "zh-Hant"),
        ("zh-VN", "zh-Hant"),
        ("kk-AF", "kk-Arab"), ("kk-CN", "kk-Arab"), ("kk-IR", "kk-Arab"), ("kk-MN", "kk-Arab"),
        ("ku-IQ", "ku-Arab"), ("ku-LB", "ku-Arab"), ("sr-RO", "sr-Latn"), ("sr-TR", "sr-Latn"),
        ("az-IR", "az-Arab"), ("az-RU", "az-Cyrl"), ("ha-CM", "ha-Arab"), ("mn-CN", "mn-Mong"),
        ("ms-CC", "ms-Arab"), ("sd-IN", "sd-Deva"), ("yue-CN", "yue-Hans"),
        ("pa-PK", "pa-Arab"), ("uz-AF", "uz-Arab"), ("uz-CN", "uz-Cyrl"),
        ("ku-AM", "und"), ("ku-AZ", "und"), ("ku-GE", "und"), ("ku-TM", "und"), ("ky-CN", "und"),
        ("ky-TR", "und"), ("lzz-GE", "und"), ("pi-IN", "und"), ("pi-LK", "und"), ("pi-MM", "und"),
        ("pi-TH", "und"), ("tg-PK", "und"),
        ("es-JP", "es-419"), ("pt-FR", "pt-PT"),
        ("ha-Latn", "ha"), ("ky-Cyrl", "ky"), ("lzz-Latn", "lzz"), ("mn-Cyrl", "mn"),
        ("ms-Latn", "ms"), ("tg-Cyrl", "tg"),
        ("ha-Latn-GH", "ha-GH"), ("ha-Latn-NE", "ha-NE"), ("kk-Cyrl-KZ", "kk-KZ"),
        ("ku-Latn-TR", "ku-TR"), ("ms-Latn-SG", "ms-SG"),
    ]

    @Test("Each place with no CLDR folder is a key of its own", arguments: placesWithNoFolder)
    func placeWithNoFolderIsAKey(_ place: (name: LocaleIdentifier, target: LocaleIdentifier)) {
        #expect(MoneyLocalization.cldr.locales.identifiers().contains(place.name.value))
    }

    @Test(
        "Each place with no CLDR folder writes money as the locale CLDR's lookup reaches",
        arguments: placesWithNoFolder
    )
    func placeWithNoFolderRendersAsItsTarget(_ place: (name: LocaleIdentifier, target: LocaleIdentifier)) throws {
        #expect(MoneyLocalization.cldr.locales.index(of: place.target) != nil)
        #expect(try Self.renderings(in: place.name) == Self.renderings(in: place.target))
    }

    @Test(
        "Each spelling of a place with no CLDR folder writes money as the locale CLDR's lookup reaches",
        arguments: [
            ("zh_TW", "zh-Hant"), ("ZH_tw", "zh-Hant"), ("ku_IQ", "ku-Arab"), ("yue_CN", "yue-Hans"),
            ("uz_AF", "uz-Arab"), ("pa_PK", "pa-Arab"), ("ku_AM", "und"), ("es_JP", "es-419"),
            ("pt_FR", "pt-PT"), ("ha-Latn-GH", "ha-GH"), ("ms-Latn-SG", "ms-SG"),
        ] as [(LocaleIdentifier, LocaleIdentifier)]
    )
    func spellingRendersAsItsTarget(_ name: LocaleIdentifier, _ target: LocaleIdentifier) throws {
        #expect(try Self.renderings(in: name) == Self.renderings(in: target))
    }

    @Test("Taiwanese Chinese writes the New Taiwan dollar as $, named in Traditional characters")
    func taiwaneseChineseDollar() throws {
        #expect(try Self.formatted(1_234_56, "TWD", in: "zh_TW") == "$1,234.56")
        #expect(try Self.fullName(1_234_56, "TWD", in: "zh_TW").contains("新台幣"))
    }

    @Test("Traditional Chinese in Taiwan, spelled with its script, writes the New Taiwan dollar as $")
    func traditionalTaiwaneseChineseDollar() throws {
        #expect(try Self.formatted(1_234_56, "TWD", in: "zh-hant-tw") == "$1,234.56")
    }

    // These keys hold the same records as the language, so only the index shows which one is reached.
    @Test(
        "A place spelled with its language's own script reaches the language-and-script key",
        arguments: [
            ("sr-Cyrl-RO", "sr-Cyrl"), ("sr_Cyrl_RO", "sr-Cyrl"), ("kk-Cyrl-CN", "kk-Cyrl"), ("mn-Cyrl-CN", "mn-Cyrl"),
        ] as [(LocaleIdentifier, LocaleIdentifier)]
    )
    func ownScriptPlaceReachesItsScriptKey(_ name: LocaleIdentifier, _ key: LocaleIdentifier) {
        let locales = MoneyLocalization.cldr.locales

        #expect(locales.identifiers().contains(key.value))
        #expect(locales.index(of: name) == locales.index(of: key))
    }

    // With no numbering system given, each locale writes CLDR's default digits, so `az-IR` writes
    // Extended Arabic-Indic digits.
    @Test(
        "A place with no CLDR folder writes the digits of the locale CLDR's lookup reaches",
        arguments: [("az-IR", "US$\u{A0}۱٬۲۳۴٫۵۶"), ("sd-IN", "$\u{A0}1,234.56")] as [(LocaleIdentifier, String)]
    )
    func placeWritesItsTargetsDigits(_ locale: LocaleIdentifier, _ expected: String) throws {
        #expect(try Self.formatted(1_234_56, "USD", in: locale) == expected)
    }

    @Test(
        "A region or script with no locale of its own still reaches its language",
        arguments: [
            ("en_US", "en"), ("de_DE", "de"), ("ko-Hang", "ko"), ("ja-Kana", "ja"),
        ] as [(LocaleIdentifier, LocaleIdentifier)]
    )
    func regionReachesItsLanguage(_ name: LocaleIdentifier, _ language: LocaleIdentifier) {
        let locales = MoneyLocalization.cldr.locales

        #expect(locales.index(of: name) == locales.index(of: language))
        #expect(locales.index(of: name) != nil)
    }

    @Test(
        "A spelling that already reached the right locale still writes money as it",
        arguments: [
            ("zh-Hans-TW", "zh"), ("ha-Latn-SD", "ha"), ("ha-Latn-SD-u-nu-latn", "ha"),
            ("sr_RS@latin", "sr"), ("zh_TW.UTF-8", "zh"),
        ] as [(LocaleIdentifier, LocaleIdentifier)]
    )
    func spellingKeepsItsLocale(_ name: LocaleIdentifier, _ expected: LocaleIdentifier) throws {
        #expect(try Self.renderings(in: name) == Self.renderings(in: expected))
    }

    @Test(
        "A spelling no locale covers still reaches nothing",
        arguments: ["zz-Latn-ZZ", "C", "POSIX", "iw", "no", "sh"] as [LocaleIdentifier]
    )
    func uncoveredSpellingReachesNothing(_ name: LocaleIdentifier) {
        #expect(MoneyLocalization.cldr.locales.index(of: name) == nil)
    }
}

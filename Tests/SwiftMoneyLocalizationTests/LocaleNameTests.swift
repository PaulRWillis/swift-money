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

    // The Arabic-script folder writes a decimal point where plain Azerbaijani writes a comma.
    @Test("Iraqi Azerbaijani reaches the Arabic-script data, not plain Azerbaijani")
    func iraqiAzerbaijani() throws {
        let short = try Self.formatted(12_34, "USD", in: "az_IQ")

        #expect(short == (try Self.formatted(12_34, "USD", in: "az-Arab-IQ")))
        #expect(short != (try Self.formatted(12_34, "USD", in: "az")))
    }
}

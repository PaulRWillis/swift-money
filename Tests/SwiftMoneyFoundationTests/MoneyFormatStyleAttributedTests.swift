import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

// The AttributedString renderer. Its load-bearing guarantee is that the attributed text equals the
// plain `format(_:)` text for every cell — engine path and ICU fallback alike — so the two forms can
// never disagree. The rest pin how runs are tagged (Foundation's numberPart/numberSymbol) and that an
// uncovered locale still renders via ICU.
@Suite("Money Format Style Attributed Tests")
struct MoneyFormatStyleAttributedTests {

    typealias Part = AttributeScopes.FoundationAttributes.NumberFormatAttributes.NumberPartAttribute.NumberPart
    typealias Symbol = AttributeScopes.FoundationAttributes.NumberFormatAttributes.SymbolAttribute.Symbol

    static func currency(_ iso: String) -> Currency {
        guard let code = CurrencyCode(string: iso), let currency = Currency(iso: code) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return currency
    }

    static func money(_ minorUnits: Int64, _ iso: String) -> Money {
        Money(minorUnits: minorUnits, currency: currency(iso))
    }

    // Each run's text and its two number attributes.
    static func tags(_ string: AttributedString) -> [(text: String, part: Part?, symbol: Symbol?)] {
        string.runs.map { run in
            (String(string[run.range].characters), run.numberPart, run.numberSymbol)
        }
    }

    // Covered locales plus a few the CLDR data does not cover, so the ICU fallback is exercised too.
    static let locales = ["en_US", "en_GB", "de_DE", "fr_FR", "ja_JP", "sw", "si", "ro", "el_GR", "pt_BR"]
    static let isos = ["USD", "GBP", "EUR", "JPY", "BHD"]
    static let amounts: [Int64] = [0, 1, 1_00, 12_34_56, -12_34_56, 1_234_567_89]
    static let presentations: [Money.FormatStyle.Configuration.Presentation] =
        [.standard, .isoCode, .narrow, .fullName]

    @Test("Attributed text equals the plain formatted text, everywhere")
    func attributedTextMatchesPlain() {
        for id in Self.locales {
            let style = Money.FormatStyle(locale: Locale(identifier: id))
            for iso in Self.isos {
                for presentation in Self.presentations {
                    let configured = style.presentation(presentation)
                    for amount in Self.amounts {
                        let money = Self.money(amount, iso)
                        let attributed = String(configured.attributed.format(money).characters)
                        #expect(attributed == configured.format(money), "\(id) \(iso) \(amount)")
                    }
                }
            }
        }
    }

    @Test("A grouped amount tags digits, separators, decimal and currency")
    func standardTagging() {
        let style = Money.FormatStyle(locale: Locale(identifier: "en_US"))
        let tagged = Self.tags(style.attributed.format(Self.money(1_234_56, "USD")))

        #expect(tagged.map(\.text) == ["$", "1", ",", "234", ".", "56"])
        #expect(tagged.map(\.symbol) == [.currency, nil, .groupingSeparator, nil, .decimalSeparator, nil])
        #expect(tagged.map(\.part) == [nil, .integer, .integer, .integer, nil, .fraction])
    }

    @Test("A negative tags the minus as a sign")
    func negativeTagsSign() {
        let style = Money.FormatStyle(locale: Locale(identifier: "en_US"))
        let tagged = Self.tags(style.attributed.format(Self.money(-5_00, "USD")))

        #expect(tagged.first?.text == "-")
        #expect(tagged.first?.symbol == .sign)
    }

    @Test("A currency name is tagged as the currency")
    func fullNameTagsCurrency() {
        let style = Money.FormatStyle(locale: Locale(identifier: "en_US")).presentation(.fullName)
        let tagged = Self.tags(style.attributed.format(Self.money(2_00, "USD")))

        #expect(tagged.contains { $0.text == "US dollars" && $0.symbol == .currency })
    }

    @Test("Engine attributed runs match ICU's for a covered locale")
    func matchesICUAttributedRuns() {
        let style = Money.FormatStyle(locale: Locale(identifier: "en_US"))
        for amount in [1_234_56 as Int64, -1_234_56, 0] {
            let ours = style.attributed.format(Self.money(amount, "USD"))
            let icu = (Decimal(amount) / 100)
                .formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")).attributed)
            func shape(_ s: AttributedString) -> String {
                Self.tags(s).map { "\($0.text)|\(String(describing: $0.part))|\(String(describing: $0.symbol))" }
                    .joined(separator: "  ")
            }
            #expect(shape(ours) == shape(icu), "amount \(amount): OURS[\(shape(ours))] ICU[\(shape(icu))]")
        }
    }

    @Test("An uncovered locale still renders via the ICU fallback")
    func uncoveredLocaleFallsBack() {
        let style = Money.FormatStyle(locale: Locale(identifier: "el_GR"))
        let attributed = style.attributed.format(Self.money(1_234_56, "EUR"))

        #expect(!String(attributed.characters).isEmpty)
        #expect(attributed.runs.contains { $0.numberSymbol == .currency })
    }

    @Test("The .currency().attributed dot syntax renders an attributed string")
    func dotSyntax() {
        let attributed = Self.money(4_99, "GBP")
            .formatted(.currency(locale: Locale(identifier: "en_GB")).attributed)

        #expect(String(attributed.characters) == "£4.99")
    }
}

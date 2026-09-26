import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import SwiftMoneyLocalization
import Testing

// A custom currency declared on its type formats through the Foundation currency style, agnostic to
// whether the currency is ISO or custom, and stays codable.
@Suite("Custom Currency FormatStyle Tests")
struct CustomCurrencyFormatStyleTests {

    static let enUS = Locale(identifier: "en_US")

    @Test("A custom currency formats through the currency style with its symbol")
    func symbolThroughStyle() {
        #expect(COIN(minorUnits: 500_00).formatted(.currency(locale: Self.enUS)) == "🪙500.00")
    }

    @Test("A custom currency formats at full name")
    func fullNameThroughStyle() {
        let text = COIN(minorUnits: 5_00).formatted(.currency(locale: Self.enUS).presentation(.fullName))
        #expect(text == "5.00 coins")
    }

    // An uncovered locale returns nil from the engine, so the style falls back to Foundation, which
    // cannot show the custom symbol (ICU does not know the code). The fallback is today's behavior.
    @Test("An uncovered locale falls back to Foundation, without the custom symbol")
    func uncoveredFallsBack() {
        let text = COIN(minorUnits: 5_00).formatted(.currency(locale: Locale(identifier: "zz-ZZ")))
        #expect(!text.isEmpty)
        #expect(!text.contains("🪙"))
    }

    // Proves the branch added no stored state: the style still encodes and compares as before.
    @Test("The style round-trips through Codable and stays Equatable")
    func styleCodable() throws {
        let style = COIN.FormatStyle(locale: Self.enUS).presentation(.fullName)
        let decoded = try JSONDecoder().decode(COIN.FormatStyle.self, from: JSONEncoder().encode(style))
        #expect(decoded == style)
    }

    // A custom currency value is codable, unaffected by the display: it encodes and decodes its amount.
    @Test("A custom currency amount round-trips through Codable")
    func amountCodable() throws {
        let coin = COIN(minorUnits: 500)
        let decoded = try JSONDecoder().decode(COIN.self, from: JSONEncoder().encode(coin))
        #expect(decoded == coin)
    }
}

// A custom currency declared under Currencies and aliased, the goal shape: format anywhere, agnostic to
// ISO vs custom.
extension Currencies {
    enum Coin: CustomCurrencyFormattable {
        static let currency: Currency = {
            guard let currency = Currency(code: "COIN", unitScale: 100) else {
                preconditionFailure("COIN must not be a currency the library ships")
            }
            return currency
        }()

        static func display(for locale: LocaleIdentifier) -> CustomCurrencyDisplay? {
            CustomCurrencyDisplay(symbol: "🪙")
        }

        static func names(for locale: LocaleIdentifier) -> CustomCurrencyNames? {
            CustomCurrencyNames(other: "coins", byCategory: [.one: "coin"])
        }
    }
}

typealias COIN = MoneyOf<Currencies.Coin>

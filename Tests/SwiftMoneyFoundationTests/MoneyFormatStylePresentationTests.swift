import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Presentation Tests")
struct MoneyFormatStylePresentationTests {
    private typealias CAD = MoneyOf<Currencies.CAD>

    private static let britishEnglish = Locale(identifier: "en_GB")
    private static let americanEnglish = Locale(identifier: "en_US")

    @Test("The standard presentation names a currency well enough to tell it from its neighbors")
    func standard() {
        let amount = CAD(minorUnits: 1_234_56)
        let style = CAD.FormatStyle().locale(Self.britishEnglish)

        #expect(style.format(amount) == "CA$1,234.56")
        #expect(style.presentation(.standard).format(amount) == "CA$1,234.56")
    }

    @Test("The narrow presentation drops the part that tells one dollar from another")
    func narrow() {
        let style = CAD.FormatStyle().locale(Self.britishEnglish).presentation(.narrow)

        #expect(style.format(CAD(minorUnits: 1_234_56)) == "$1,234.56")

        // Nothing to drop where the locale's own currency is the one being shown.
        let dollars = USD.FormatStyle().locale(Self.americanEnglish)

        #expect(dollars.presentation(.narrow).format(USD(minorUnits: 1_234_56)) == "$1,234.56")
        #expect(dollars.format(USD(minorUnits: 1_234_56)) == "$1,234.56")
    }

    @Test("The ISO code presentation writes the code and a no-break space")
    func isoCode() {
        let style = CAD.FormatStyle().locale(Self.britishEnglish).presentation(.isoCode)

        #expect(style.format(CAD(minorUnits: 1_234_56)) == "CAD\u{00A0}1,234.56")

        let sterling = GBP.FormatStyle().locale(Self.britishEnglish).presentation(.isoCode)

        #expect(sterling.format(GBP(minorUnits: 1_234_56)) == "GBP\u{00A0}1,234.56")
    }

    @Test("The full name presentation spells the currency out after the digits")
    func fullName() {
        let style = CAD.FormatStyle().locale(Self.britishEnglish).presentation(.fullName)

        #expect(style.format(CAD(minorUnits: 1_234_56)) == "1,234.56 Canadian dollars")

        let sterling = GBP.FormatStyle().locale(Self.britishEnglish).presentation(.fullName)

        #expect(sterling.format(GBP(minorUnits: 1_234_56)) == "1,234.56 British pounds")
    }

    @Test("A runtime amount presents itself the same as its typed twin")
    func runtimeAmountMatchesTypedTwin() {
        let typed = CAD.FormatStyle().locale(Self.britishEnglish)
        let runtime = Money.FormatStyle().locale(Self.britishEnglish)

        for presentation in [
            CurrencyFormatStyleConfiguration.Presentation.standard,
            .narrow,
            .isoCode,
            .fullName,
        ] {
            #expect(
                runtime.presentation(presentation)
                    .format(Money(minorUnits: 1_234_56, currency: .cad))
                    == typed.presentation(presentation).format(CAD(minorUnits: 1_234_56))
            )
        }
    }
}

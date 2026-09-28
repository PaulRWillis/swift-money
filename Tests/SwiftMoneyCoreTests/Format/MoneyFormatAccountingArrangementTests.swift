import SwiftMoneyCore
import Testing

// The accounting sign strategy can move the currency to the *other* side than the standard
// presentation uses (as `no`'s CLDR data does): `accountingArrangement` carries that side's pattern
// and grouping, read only when `.accounting` asks for it. A `nil` arrangement (the common case) leaves
// every strategy, including `.accounting`, reading the standard `pattern`/`grouping` exactly as before.
@Suite("MoneyFormat accounting arrangement")
struct MoneyFormatAccountingArrangementTests {

    static func money(_ minorUnits: Int64, _ iso: CurrencyCode) -> Money {
        guard let currency = Currency(iso: iso) else {
            preconditionFailure("\(iso) must be a shipped ISO currency")
        }
        return Money(minorUnits: minorUnits, currency: currency)
    }

    // A trailing standard pattern ("#,##0.00 kr") with a leading accounting arrangement
    // ("kr #,##0.00"), as `no` arranges its own currency: the accounting *positive* moves side, which
    // a pattern's own `accountingNegative` field cannot express.
    static let leadingAccounting = MoneyFormat.Arrangement(
        pattern: MoneyFormatTests.pattern(currencyFirst: true),
        grouping: .repeating(3, separator: ",")
    )

    static let sidedKroner = MoneyFormat(
        symbol: "kr",
        pattern: MoneyFormatTests.pattern(currencyFirst: false),
        accountingArrangement: leadingAccounting
    )

    @Test("A positive amount renders leading under .accounting when the arrangement moves the side")
    func accountingMovesThePositiveLeading() {
        #expect(
            Self.sidedKroner.format(Self.money(1_234_56, "USD"), options: .init(sign: .accounting))
                == "kr1,234.56"
        )
    }

    @Test("The same positive amount stays trailing under .automatic")
    func automaticStaysTrailing() {
        #expect(Self.sidedKroner.format(Self.money(1_234_56, "USD")) == "1,234.56kr")
    }

    @Test("A nil accounting arrangement is byte-identical to the standard pattern under .accounting")
    func nilArrangementMatchesStandard() {
        let plain = MoneyFormat(symbol: "kr", pattern: MoneyFormatTests.pattern(currencyFirst: false))

        #expect(
            plain.format(Self.money(1_234_56, "USD"), options: .init(sign: .accounting))
                == plain.format(Self.money(1_234_56, "USD"))
        )
    }

    @Test("The run seam also reads the accounting arrangement for a positive amount")
    func runsAlsoMoveTheSide() {
        let runs = Self.sidedKroner.runs(Self.money(1_234_56, "USD"), options: .init(sign: .accounting))

        #expect(runs.first == .currency("kr"))
    }
}

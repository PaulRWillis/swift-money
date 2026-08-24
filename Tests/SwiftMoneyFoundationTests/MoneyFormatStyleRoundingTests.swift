import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("Money Format Style Rounding Tests")
struct MoneyFormatStyleRoundingTests {
    private typealias CHF = MoneyOf<Currencies.CHF>

    // One amount, the rule it is rounded under, and the text a ten-centime step then shows.
    struct Rounding: Sendable {
        let rule: FloatingPointRoundingRule
        let minorUnits: Int
        let shows: String
    }

    private static let britishEnglish = Locale(identifier: "en_GB")

    private static let everyRule: [FloatingPointRoundingRule] = [
        .down,
        .up,
        .towardZero,
        .awayFromZero,
        .toNearestOrEven,
        .toNearestOrAwayFromZero,
    ]

    private static var francs: CHF.FormatStyle {
        CHF.FormatStyle().locale(britishEnglish)
    }

    @Test(
        "Each rounding rule moves a part-step amount its own way",
        arguments: [
            Rounding(rule: .down, minorUnits: 4_83, shows: "CHF\u{00A0}4.80"),
            Rounding(rule: .down, minorUnits: -4_83, shows: "-CHF\u{00A0}4.90"),
            Rounding(rule: .up, minorUnits: 4_83, shows: "CHF\u{00A0}4.90"),
            Rounding(rule: .up, minorUnits: -4_83, shows: "-CHF\u{00A0}4.80"),
            Rounding(rule: .towardZero, minorUnits: 4_83, shows: "CHF\u{00A0}4.80"),
            Rounding(rule: .towardZero, minorUnits: -4_83, shows: "-CHF\u{00A0}4.80"),
            Rounding(rule: .awayFromZero, minorUnits: 4_83, shows: "CHF\u{00A0}4.90"),
            Rounding(rule: .awayFromZero, minorUnits: -4_83, shows: "-CHF\u{00A0}4.90"),
            Rounding(rule: .toNearestOrEven, minorUnits: 4_83, shows: "CHF\u{00A0}4.80"),
            Rounding(rule: .toNearestOrEven, minorUnits: 4_87, shows: "CHF\u{00A0}4.90"),
            Rounding(rule: .toNearestOrAwayFromZero, minorUnits: 4_83, shows: "CHF\u{00A0}4.80"),
            Rounding(rule: .toNearestOrAwayFromZero, minorUnits: 4_87, shows: "CHF\u{00A0}4.90"),
        ]
    )
    func rulesMovePartStepAmountsTheirOwnWay(_ rounding: Rounding) {
        let style = Self.francs.rounded(rule: rounding.rule, increment: 10)

        #expect(style.format(CHF(minorUnits: rounding.minorUnits)) == rounding.shows)
    }

    @Test(
        "The two nearest rules part company on an exact half step",
        arguments: [
            Rounding(rule: .toNearestOrEven, minorUnits: 4_85, shows: "CHF\u{00A0}4.80"),
            Rounding(rule: .toNearestOrEven, minorUnits: 4_95, shows: "CHF\u{00A0}5.00"),
            Rounding(rule: .toNearestOrEven, minorUnits: -4_85, shows: "-CHF\u{00A0}4.80"),
            Rounding(rule: .toNearestOrAwayFromZero, minorUnits: 4_85, shows: "CHF\u{00A0}4.90"),
            Rounding(rule: .toNearestOrAwayFromZero, minorUnits: 4_95, shows: "CHF\u{00A0}5.00"),
            Rounding(rule: .toNearestOrAwayFromZero, minorUnits: -4_85, shows: "-CHF\u{00A0}4.90"),
        ]
    )
    func nearestRulesPartCompanyOnAHalfStep(_ rounding: Rounding) {
        let style = Self.francs.rounded(rule: rounding.rule, increment: 10)

        #expect(style.format(CHF(minorUnits: rounding.minorUnits)) == rounding.shows)
    }

    @Test("An amount already on a step is left alone by every rule", arguments: everyRule)
    func amountsOnAStepAreLeftAlone(rule: FloatingPointRoundingRule) {
        let style = Self.francs.rounded(rule: rule, increment: 25)

        #expect(style.format(CHF(minorUnits: 4_75)) == "CHF\u{00A0}4.75")
        #expect(style.format(CHF(minorUnits: -4_75)) == "-CHF\u{00A0}4.75")
    }

    @Test("A step of one rounds nothing, an amount already being whole smallest units")
    func aStepOfOneRoundsNothing() {
        let style = Self.francs.rounded(rule: .up, increment: 1)

        #expect(style.format(CHF(minorUnits: 4_98)) == "CHF\u{00A0}4.98")
    }

    @Test("A step below one traps, being a mistake in the source", arguments: [0, -5])
    func stepsBelowOneTrap(increment: Int) async {
        await #expect(processExitsWith: .failure) { [increment] in
            blackHole(CHF.FormatStyle().rounded(increment: increment))
        }
    }

    @Test("Foundation loses the currency symbol when an increment meets a fraction length")
    func foundationLosesTheSymbolOnAnIncrementBesideAFractionLength() {
        // Why this suite rounds increments itself instead of handing them to ICU. Foundation
        // counts an increment in major units and, set beside a fraction length, writes neither
        // the symbol nor the rounding: 4.98 comes back as "4.98". Pinned against Foundation
        // directly, because our own style never asks it to do this. The day this test resolves,
        // pairing an increment with a fraction length is safe again, but the hand-rolled rounding
        // still stays: Foundation's increment is an `Int` of major units, so a five-centime step
        // has no way to be written at all. Verified on Swift 6.3.2.
        let sut = Decimal.FormatStyle.Currency(code: "CHF", locale: Self.britishEnglish)
            .precision(.fractionLength(2))
            .rounded(rule: .toNearestOrEven, increment: 5)

        withKnownIssue("Foundation drops the currency symbol and ignores the increment") {
            let value = try #require(Decimal(string: "4.98"))

            #expect(sut.format(value) == "CHF\u{00A0}5.00")
        }
    }

    @Test("Rounding an amount at the end of the range renders rather than overflowing")
    func roundsAtTheEndOfTheRange() {
        let greatest = Self.francs.rounded(rule: .up, increment: 5)
        let least = Self.francs.rounded(rule: .down, increment: 5)

        #expect(greatest.format(CHF.max) == "CHF\u{00A0}92,233,720,368,547,758.10")
        #expect(least.format(CHF.min) == "-CHF\u{00A0}92,233,720,368,547,758.10")
    }

    @Test("A yen amount rounds by whole yen, its smallest unit being its major one")
    func roundsACurrencyWithNoSubunit() {
        let style = JPY.FormatStyle().locale(Self.britishEnglish).rounded(increment: 100)

        #expect(style.format(JPY(minorUnits: 1_234)) == "JP¥1,200")
        #expect(style.format(JPY(minorUnits: 1_250)) == "JP¥1,200")
        #expect(style.format(JPY(minorUnits: 1_350)) == "JP¥1,400")
    }
}

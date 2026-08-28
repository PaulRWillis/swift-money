import SwiftMoneyCore
import Testing

// Currencies at scales other than the sterling hundredth, all powers of ten.
private enum Tenths: CurrencyType {
    static let currency = customCurrency(code: "TEN", unitScale: 10)
}

private enum Mills: CurrencyType {
    static let currency = customCurrency(code: "MIL", unitScale: 1_000)
}

@Suite("Money Description Tests")
struct MoneyDescriptionTests {

    @Test(
        "An amount is written in major units, to the places its currency divides into",
        arguments: [
            (GBP(minorUnits: 4_99), "GBP 4.99"),
            (GBP(minorUnits: 5), "GBP 0.05"),
            (GBP(minorUnits: 0), "GBP 0.00"),
            (GBP(minorUnits: 99_999_999), "GBP 999999.99"),
        ]
    )
    func writesMajorUnits(_ amount: GBP, _ expected: String) {
        #expect(String(describing: amount) == expected)
    }

    @Test("A negative amount keeps its sign in front of the whole part")
    func negativeAmount() {
        #expect(String(describing: GBP(minorUnits: -4_99)) == "GBP -4.99")
        #expect(String(describing: GBP(minorUnits: -5)) == "GBP -0.05")
    }

    @Test("A currency dividing into a thousand is written to three places")
    func threePlaces() {
        #expect(String(describing: MoneyOf<Currencies.KWD>(minorUnits: 1)) == "KWD 0.001")
        #expect(String(describing: MoneyOf<Currencies.KWD>(minorUnits: 4_990)) == "KWD 4.990")
    }

    @Test("A currency with no subunits is written whole")
    func noSubunits() {
        #expect(String(describing: JPY(minorUnits: 499)) == "JPY 499")
        #expect(String(describing: JPY(minorUnits: -7)) == "JPY -7")
    }

    @Test(
        "A scale is written to the number of places it reaches",
        arguments: [
            (String(describing: MoneyOf<Tenths>(minorUnits: 6)), "TEN 0.6"),
            (String(describing: MoneyOf<Tenths>(minorUnits: -6)), "TEN -0.6"),
            (String(describing: MoneyOf<Mills>(minorUnits: 125)), "MIL 0.125"),
            (String(describing: MoneyOf<Mills>(minorUnits: 875)), "MIL 0.875"),
        ]
    )
    func writesToThePlacesTheScaleReaches(_ written: String, _ expected: String) {
        #expect(written == expected)
    }

    // The smallest amount has no positive counterpart, so anything that negates it overflows.
    @Test("The extremes of the range are written without trapping")
    func extremes() {
        #expect(String(describing: GBP.min) == "GBP -92233720368547758.08")
        #expect(String(describing: GBP.max) == "GBP 92233720368547758.07")
    }

    @Test("An amount reads the same whether its currency is fixed by its type or carried")
    func runtimeMatchesTyped() {
        let carried = Money(minorUnits: 4_99, currency: .gbp)

        #expect(String(describing: carried) == String(describing: GBP(minorUnits: 4_99)))
    }

    @Test("A currency known only at runtime is written from the scale it carries")
    func runtimeUsesItsOwnScale() {
        let carried = Money(minorUnits: 875, currency: customCurrency(code: "MIL", unitScale: 1_000))

        #expect(String(describing: carried) == "MIL 0.875")
    }

    @Test("Interpolating an amount uses the same form")
    func interpolation() {
        #expect("costs \(GBP(minorUnits: 4_99))" == "costs GBP 4.99")
    }
}

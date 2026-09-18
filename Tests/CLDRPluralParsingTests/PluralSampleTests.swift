import CLDRPluralParsing
import SwiftMoneyCore
import Testing

@Suite("PluralSample Tests")
struct PluralSampleTests {

    @Test("A sample reads back as CLDR writes it", arguments: [
        (minorUnits: 1_30 as Int64, scale: 100 as UnitScale, text: "1.30"),
        (minorUnits: 5, scale: 100, text: "0.05"),
        (minorUnits: 0, scale: 10, text: "0.0"),
        (minorUnits: 1_000_000, scale: 1, text: "1000000"),
    ])
    func sampleReadsAsCLDRWritesIt(_ row: (minorUnits: Int64, scale: UnitScale, text: String)) {
        let sample = PluralSample(minorUnits: row.minorUnits, unitScale: row.scale)

        #expect(sample.description == row.text)
    }
}

import Foundation
import SwiftMoney
import SwiftMoneyFoundation
import Testing

@Suite("JSONDecoder MoneyCodingFormat Tests")
struct JSONDecoderMoneyCodingFormatTests {

    @Test("An unset decoder reports its format, and reads a number as minor units")
    func defaultsToCodedString() throws {
        let decoder = JSONDecoder()

        #expect(decoder.moneyCodingFormat == .codedString)
        #expect(try decoder.decode(GBP.self, from: Data("499".utf8)) == GBP(minorUnits: 4_99))
    }

    @Test("A format that is set reads back")
    func readsBackASetFormat() {
        let decoder = JSONDecoder()

        decoder.moneyCodingFormat = .fields(currencyKey: "ccy", amountKey: "value")

        #expect(decoder.moneyCodingFormat == .fields(currencyKey: "ccy", amountKey: "value"))
    }

    @Test("A set format supplies the field names the decoder reads")
    func decodesWithTheSetFormat() throws {
        let decoder = JSONDecoder()

        decoder.moneyCodingFormat = .fields(currencyKey: "ccy", amountKey: "value")

        let payload = Data(#"{"ccy":"GBP","value":499}"#.utf8)

        #expect(try decoder.decode(GBP.self, from: payload) == GBP(minorUnits: 4_99))
    }
}

import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation
import Testing

@Suite("JSONEncoder MoneyCodingFormat Tests")
struct JSONEncoderMoneyCodingFormatTests {

    @Test("An unset encoder reports the format it writes")
    func defaultsToCodedString() throws {
        let encoder = JSONEncoder()

        #expect(encoder.moneyCodingFormat == .codedString)
        #expect(String(decoding: try encoder.encode(GBP(minorUnits: 4_99)), as: UTF8.self) == "\"GBP 499\"")
    }

    @Test("A format that is set reads back")
    func readsBackASetFormat() {
        let encoder = JSONEncoder()

        encoder.moneyCodingFormat = .fields

        #expect(encoder.moneyCodingFormat == .fields)
    }

    @Test("A set format shapes what the encoder writes")
    func encodesWithTheSetFormat() throws {
        let encoder = JSONEncoder()

        encoder.outputFormatting = .sortedKeys
        encoder.moneyCodingFormat = .fields()

        let payload = String(decoding: try encoder.encode(GBP(minorUnits: 4_99)), as: UTF8.self)

        #expect(payload == #"{"amount":499,"currency":"GBP"}"#)
    }
}

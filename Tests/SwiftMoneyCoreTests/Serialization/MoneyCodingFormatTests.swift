import SwiftMoneyCore
import Testing

@Suite("MoneyCodingFormat Tests")
struct MoneyCodingFormatTests {

    @Test("Distinct custom keys are accepted")
    func distinctKeysAreAccepted() throws {
        _ = try MoneyCodingFormat.fields(currencyKey: "ccy", amountKey: "value")
    }

    @Test("The same key for currency and amount is refused, whatever currency is later encoded")
    func currencyKeySameAsAmountKeyIsRefused() {
        #expect(throws: MoneyCodingFormatError.duplicateFieldKey("foo")) {
            try MoneyCodingFormat.fields(currencyKey: "foo", amountKey: "foo")
        }
    }

    @Test("A currency key of \"scale\" is refused")
    func currencyKeyMatchingScaleIsRefused() {
        #expect(throws: MoneyCodingFormatError.duplicateFieldKey("scale")) {
            try MoneyCodingFormat.fields(currencyKey: "scale", amountKey: "amount")
        }
    }

    @Test("An amount key of \"scale\" is refused, for the same reason")
    func amountKeyMatchingScaleIsRefused() {
        #expect(throws: MoneyCodingFormatError.duplicateFieldKey("scale")) {
            try MoneyCodingFormat.fields(currencyKey: "currency", amountKey: "scale")
        }
    }

    @Test("The default keys never need the throwing overload")
    func defaultsStayNonThrowing() {
        #expect(MoneyCodingFormat.fields == MoneyCodingFormat.fields())
    }
}

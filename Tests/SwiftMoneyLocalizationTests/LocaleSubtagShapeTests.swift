import SwiftMoneyLocalization
import Testing

@Suite("Locale Subtag Shape Tests")
struct LocaleSubtagShapeTests {

    @Test("Four ASCII letters are a script in any case", arguments: ["Latn", "latn", "LATN"])
    func script(_ subtag: String) {
        #expect(LocaleSubtagShape(subtag.utf8) == .script)
    }

    @Test("Two ASCII letters or three digits are a region in any case", arguments: ["GB", "gb", "419"])
    func region(_ subtag: String) {
        #expect(LocaleSubtagShape(subtag.utf8) == .region)
    }

    @Test(
        "Anything else has no shape",
        arguments: ["Ääää", "4190", "G1", "1G", "41", "GBR", "Lat1", "Latin", "", "e", "valencia"]
    )
    func noShape(_ subtag: String) {
        #expect(LocaleSubtagShape(subtag.utf8) == nil)
    }
}

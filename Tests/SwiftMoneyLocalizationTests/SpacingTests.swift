import SwiftMoneyLocalization
import Testing

@Suite("Spacing Tests")
struct SpacingTests {

    @Test("Each spacing writes the characters CLDR uses for it", arguments: [
        (Spacing.none, ""),
        (.asciiSpace, " "),
        (.nonBreakingSpace, "\u{00A0}"),
        (.narrowNonBreakingSpace, "\u{202F}"),
    ])
    func spacingWritesItsCharacters(_ spacing: Spacing, _ rendered: String) {
        #expect(spacing.rendered == rendered)
    }

    @Test("A gap CLDR writes is recognized", arguments: ["", " ", "\u{00A0}", "\u{202F}"])
    func knownGapsAreRecognized(_ text: String) throws {
        let spacing = try #require(Spacing(rendering: text))

        #expect(spacing.rendered == text)
    }

    @Test("A gap this engine does not model is refused", arguments: ["  ", "\t", " de "])
    func unmodelledGapsAreRefused(_ text: String) {
        #expect(Spacing(rendering: text) == nil)
    }
}

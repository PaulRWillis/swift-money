import SwiftMoneyCore
import Testing

@Suite("GroupingSeparator Tests")
struct GroupingSeparatorTests {

    @Test("A separator built from a runtime string equals the same string literal")
    func fromString() {
        // A non-literal argument so this exercises `init(_:)`, not the string-literal init.
        let raw = String(repeating: "\u{202F}", count: 1)
        #expect(GroupingSeparator(raw) == "\u{202F}")
    }

    @Test("A separator built from an empty string returns nil")
    func fromEmptyString() {
        // A non-literal empty string reaches `init(_:)`; an empty literal would trap instead.
        let empty = String(repeating: " ", count: 0)
        #expect(GroupingSeparator(empty) == nil)
    }

    @Test("Literal: an empty separator traps")
    func fromEmptyLiteral() async {
        await #expect(processExitsWith: .failure) {
            let _: GroupingSeparator = ""
        }
    }
}

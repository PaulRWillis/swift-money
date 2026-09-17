import SwiftMoneyCore
import Testing

@Suite("GroupingSize Tests")
struct GroupingSizeTests {

    @Test("Init from the smallest valid value succeeds")
    func initFromSmallestValid() {
        #expect(GroupingSize(exactly: 1) != nil)
    }

    @Test("Init from zero returns nil")
    func initFromZero() {
        #expect(GroupingSize(exactly: 0) == nil)
    }

    @Test("Init from a negative value returns nil")
    func initFromNegative() {
        #expect(GroupingSize(exactly: -1) == nil)
    }

    @Test("Literal: init from zero traps")
    func initFromZeroLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = GroupingSize(0)
        }
    }
}

@Suite("FractionLength Tests")
struct FractionLengthTests {

    @Test("Init from zero succeeds")
    func initFromZero() {
        #expect(FractionLength(exactly: 0) != nil)
    }

    @Test("Init from a negative value returns nil")
    func initFromNegative() {
        #expect(FractionLength(exactly: -1) == nil)
    }

    @Test("Literal: init from a negative value traps")
    func initFromNegativeLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = FractionLength(-1)
        }
    }
}

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

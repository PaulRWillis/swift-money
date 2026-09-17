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

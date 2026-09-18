import SwiftMoneyLocalization
import Testing

@Suite("PluralCategory Tests")
struct PluralCategoryTests {

    @Test("Every category is named as CLDR names it", arguments: [
        ("zero", PluralCategory.zero),
        ("one", .one),
        ("two", .two),
        ("few", .few),
        ("many", .many),
        ("other", .other),
    ])
    func cldrNamesTheCategories(_ name: String, _ category: PluralCategory) {
        #expect(PluralCategory(rawValue: name) == category)
    }

    @Test("A name CLDR does not use names no category")
    func unknownNameIsRejected() {
        #expect(PluralCategory(rawValue: "several") == nil)
    }

    @Test("The categories are ordered as CLDR resolves them, with other last")
    func categoriesAreInResolutionOrder() {
        #expect(PluralCategory.allCases == [.zero, .one, .two, .few, .many, .other])
    }
}

import SwiftMoneyLocalization
import Testing

// The selection type: automatic and explicit are distinct cases, an explicit selection carries its system,
// and value semantics hold.
@Suite("Numbering System Selection Tests")
struct NumberingSystemSelectionTests {

    @Test("automatic differs from any explicit selection")
    func automaticDiffersFromExplicit() {
        #expect(NumberingSystemSelection.automatic != .explicit(.arabicIndic))
    }

    @Test("Explicit selections match by their system and differ across systems")
    func explicitMatchesBySystem() {
        #expect(NumberingSystemSelection.explicit(.arabicIndic) == .explicit(.arabicIndic))
        #expect(NumberingSystemSelection.explicit(.arabicIndic) != .explicit(.devanagari))
    }

    @Test("Equal selections hash together")
    func equalSelectionsHashTogether() {
        let selections: Set<NumberingSystemSelection> = [
            .automatic, .automatic, .explicit(.latin), .explicit(.latin),
        ]
        #expect(selections == [.automatic, .explicit(.latin)])
    }
}

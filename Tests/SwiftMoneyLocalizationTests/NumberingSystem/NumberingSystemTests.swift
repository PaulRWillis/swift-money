import SwiftMoneyLocalization
import Testing

// The vetted numbering-system type: distinct constants, value semantics, and a failable initializer that
// admits only supported systems.
@Suite("Numbering System Tests")
struct NumberingSystemTests {

    @Test("Distinct systems are not equal")
    func distinctSystemsDiffer() {
        #expect(NumberingSystem.arabicIndic != NumberingSystem.devanagari)
        #expect(NumberingSystem.latin != NumberingSystem.bengali)
    }

    @Test("The same system is equal and hashes together")
    func sameSystemMatches() {
        #expect(NumberingSystem.arabicIndic == NumberingSystem("arab"))
        #expect(Set([NumberingSystem.arabicIndic, NumberingSystem("arab")]).count == 1)
    }

    @Test("The failable initializer maps a supported CLDR name")
    func initializerMapsSupported() {
        #expect(NumberingSystem("arab") == .arabicIndic)
        #expect(NumberingSystem("deva") == .devanagari)
        #expect(NumberingSystem("latn") == .latin)
    }

    @Test("The failable initializer rejects an unsupported or unknown name")
    func initializerRejectsUnsupported() {
        #expect(NumberingSystem("hanidec") == nil)   // numeric but not representable
        #expect(NumberingSystem("roman") == nil)     // algorithmic
        #expect(NumberingSystem("nonsense") == nil)  // unknown
        #expect(NumberingSystem("") == nil)
    }

    @Test("Exactly the 77 representable systems are exposed, all distinct")
    func exposesSeventySeven() {
        #expect(NumberingSystem.all.count == 77)
        #expect(Set(NumberingSystem.all).count == 77)
    }

    @Test("Every exposed constant round-trips through the failable initializer")
    func constantsRoundTrip() {
        for system in NumberingSystem.all {
            #expect(NumberingSystem(system.identifier) == system)
        }
    }
}

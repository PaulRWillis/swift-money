import SwiftMoney
import Testing

@Suite("Fixed Arithmetic Tests")
struct FixedArithmeticTests {

    @Test("Addition sums the raw values")
    func additionSums() {
        #expect(Fixed(raw: 2) + Fixed(raw: 3) == Fixed(raw: 5))
        #expect(Fixed(raw: 5) + Fixed(raw: -3) == Fixed(raw: 2))
        #expect(Fixed(raw: -2) + Fixed(raw: -3) == Fixed(raw: -5))
        #expect(Fixed(raw: 7) + Fixed(raw: -7) == .zero)
    }

    @Test("Subtraction takes the difference of the raw values")
    func subtractionDiffers() {
        #expect(Fixed(raw: 5) - Fixed(raw: 3) == Fixed(raw: 2))
        #expect(Fixed(raw: 3) - Fixed(raw: 5) == Fixed(raw: -2))
        #expect(Fixed(raw: -3) - Fixed(raw: -3) == .zero)
    }

    @Test("Addition past the maximum traps")
    func additionOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: .max) + Fixed(raw: 1))
        }
    }

    @Test("Subtraction past the minimum traps")
    func subtractionOverflowTraps() async {
        await #expect(processExitsWith: .failure) {
            blackHole(Fixed(raw: .min) - Fixed(raw: 1))
        }
    }
}

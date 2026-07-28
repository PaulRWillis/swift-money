import POCMoney
import Testing

@Suite("DistributionParts Tests")
struct DistributionPartsTests {

    // MARK: - Initialization

    @Test("Init from smallest valid value succeeds")
    func initFromSmallestValid() {
        let int: Int = 1
        #expect(DistributionParts(int) != nil)
    }

    @Test("Init from biggest positive succeeds")
    func initFromBiggestPositive() {
        let int: Int = .max
        #expect(DistributionParts(int) != nil)
    }

    @Test("Init from zero returns nil")
    func initFromZero() {
        let int: Int = .zero
        #expect(DistributionParts(int) == nil)
    }

    @Test("Init from smallest negative returns nil")
    func initFromSmallestNegative() {
        let int: Int = -1
        #expect(DistributionParts(int) == nil)
    }

    @Test("Init from biggest negative returns nil")
    func initFromBiggestNegative() {
        let int: Int = .min
        #expect(DistributionParts(int) == nil)
    }

    // MARK: - ExpressibleByIntegerLiteral Initialization

    @Test("Literal: Init from smallest valid value succeeds")
    func initFromSmallestValidLiteral() async {
        await #expect(processExitsWith: .success) {
            _ = DistributionParts(1)
        }
    }

    @Test("Literal: Init from biggest positive succeeds")
    func initFromBiggestPositiveLiteral() async {
        await #expect(processExitsWith: .success) {
            _ = DistributionParts(9223372036854775807)
        }
    }

    @Test("Literal: Init from zero traps")
    func initFromZeroLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = DistributionParts(0)
        }
    }

    @Test("Literal: Init from smallest negative traps")
    func initFromSmallestNegativeLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = DistributionParts(-1)
        }
    }

    @Test("Literal: Init from biggest negative traps")
    func initFromBiggestNegativeLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = DistributionParts(-9223372036854775808)
        }
    }

    // MARK: - Int Conversion

    @Test("Int conversion returns the underlying value")
    func intConversion() {
        let parts: DistributionParts = 3

        #expect(Int(parts) == 3)
    }

    // MARK: - Comparable

    @Test("Fewer parts compare as less than more parts")
    func comparableOrdersByPartCount() {
        let fewer: DistributionParts = 2
        let more: DistributionParts = 5

        #expect(fewer < more)
        #expect(more > fewer)
    }

    @Test("Equal part counts are equatable")
    func equalPartCountsAreEquatable() {
        let a: DistributionParts = 4
        let b: DistributionParts = 4

        #expect(a == b)
    }
}

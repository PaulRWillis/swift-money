import SwiftMoney
import Testing

@Suite("PartCount Tests")
struct PartCountTests {

    // MARK: - Initialization

    @Test("Init from smallest valid value succeeds")
    func initFromSmallestValid() {
        let int: Int = 1
        #expect(PartCount(exactly: int) != nil)
    }

    @Test("Init from biggest positive succeeds")
    func initFromBiggestPositive() {
        let int: Int = .max
        #expect(PartCount(exactly: int) != nil)
    }

    @Test("Init from zero returns nil")
    func initFromZero() {
        let int: Int = .zero
        #expect(PartCount(exactly: int) == nil)
    }

    @Test("Init from smallest negative returns nil")
    func initFromSmallestNegative() {
        let int: Int = -1
        #expect(PartCount(exactly: int) == nil)
    }

    @Test("Init from biggest negative returns nil")
    func initFromBiggestNegative() {
        let int: Int = .min
        #expect(PartCount(exactly: int) == nil)
    }

    // MARK: - ExpressibleByIntegerLiteral Initialization

    @Test("Literal: Init from smallest valid value succeeds")
    func initFromSmallestValidLiteral() async {
        await #expect(processExitsWith: .success) {
            _ = PartCount(1)
        }
    }

    @Test("Literal: Init from biggest positive succeeds")
    func initFromBiggestPositiveLiteral() async {
        await #expect(processExitsWith: .success) {
            _ = PartCount(9223372036854775807)
        }
    }

    @Test("Literal: Init from zero traps")
    func initFromZeroLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = PartCount(0)
        }
    }

    @Test("Literal: Init from smallest negative traps")
    func initFromSmallestNegativeLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = PartCount(-1)
        }
    }

    @Test("Literal: Init from biggest negative traps")
    func initFromBiggestNegativeLiteral() async {
        await #expect(processExitsWith: .failure) {
            _ = PartCount(-9223372036854775808)
        }
    }

    // MARK: - Int Conversion

    @Test("Int conversion returns the underlying value")
    func intConversion() {
        let parts: PartCount = 3

        #expect(Int(parts) == 3)
    }

    @Test("Int64 conversion returns the underlying value", arguments: [1, 3, 1_000_000])
    func int64Conversion(_ raw: Int) throws {
        let parts = try #require(PartCount(exactly: raw))

        #expect(Int64(parts) == Int64(raw))
    }

    // MARK: - Comparable

    @Test("Fewer parts compare as less than more parts")
    func comparableOrdersByPartCount() {
        let fewer: PartCount = 2
        let more: PartCount = 5

        #expect(fewer < more)
        #expect(more > fewer)
    }

    @Test("Equal part counts are equatable")
    func equalPartCountsAreEquatable() {
        let a: PartCount = 4
        let b: PartCount = 4

        #expect(a == b)
    }
}

import SwiftMoneyCore
import Testing

// The serializer exists only where `InlineArray` does (macOS 26 and up). `@Test` cannot sit on an
// availability-limited function, so each test guards with `#available` and no-ops on older systems.
@Suite("Unrounded byte serialization")
struct UnroundedBytesTests {

    static let scales: [(code: CurrencyCode, unitScale: UnitScale)] = [
        ("JPY", 1),
        ("GBP", 100),
        ("KWD", 1_000),
        ("CLF", 10_000),
        ("BTC", 100_000_000),
        ("ETH", 1_000_000_000_000_000_000),
    ]

    static let seeds: [Int64] = [0, 1, -1, 4_99, -4_99, 1_000_000, .max, .min]

    static func currency(_ code: CurrencyCode, _ scale: UnitScale) -> Currency {
        customCurrency(code: code, unitScale: scale)
    }

    @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
    static func array(_ bytes: InlineArray<23, UInt8>) -> [UInt8] {
        var result: [UInt8] = []
        for index in 0 ..< bytes.count {
            result.append(bytes[index])
        }
        return result
    }

    @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
    static func bytes(_ raw: [UInt8]) -> InlineArray<23, UInt8> {
        precondition(raw.count == 23, "an unrounded encoding is twenty-three bytes")
        return InlineArray<23, UInt8> { raw[$0] }
    }

    @Test("An encoding is twenty-three bytes")
    func encodingIsTwentyThreeBytes() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        #expect(GBP.Unrounded.byteCount == 23)
        #expect(Money.Unrounded.byteCount == 23)
        #expect(Self.array(GBP(minorUnits: 4_99).unrounded.bytes).count == 23)
    }

    @Test(
        "A whole runtime amount round-trips at every scale and sign",
        arguments: scales, seeds
    )
    func wholeRuntimeRoundTrip(_ scale: (code: CurrencyCode, unitScale: UnitScale), _ seed: Int64) {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let original = Money(minorUnits: seed, currency: Self.currency(scale.code, scale.unitScale)).unrounded

        #expect(Money.Unrounded(bytes: original.bytes) == original)
    }

    // The reason `Unrounded` exists: a fraction of a minor unit that a settled amount cannot hold. The
    // encoding must carry it back exactly, so this divides a whole amount into a repeating fraction.
    @Test(
        "A fractional runtime amount round-trips at every scale and sign",
        arguments: scales, seeds
    )
    func fractionalRuntimeRoundTrip(_ scale: (code: CurrencyCode, unitScale: UnitScale), _ seed: Int64) {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let original = Money(minorUnits: seed, currency: Self.currency(scale.code, scale.unitScale))
            .unrounded.divided(by: 7)

        #expect(Money.Unrounded(bytes: original.bytes) == original)
    }

    @Test("A typed fractional amount round-trips", arguments: seeds)
    func typedRoundTrip(_ seed: Int64) {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let original = GBP(minorUnits: seed).unrounded.divided(by: 7)

        #expect(GBP.Unrounded(bytes: original.bytes) == original)
    }

    @Test("A typed amount and the same runtime amount encode identically")
    func typedAndRuntimeAgree() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let typed = GBP(minorUnits: 10_00).unrounded.divided(by: 3)
        let runtime = Money(minorUnits: 10_00, currency: .gbp).unrounded.divided(by: 3)

        #expect(Self.array(typed.bytes) == Self.array(runtime.bytes))
    }

    @Test("Typed bytes decode as the matching runtime amount")
    func typedDecodesAsRuntime() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let typed = GBP(minorUnits: 10_00).unrounded.divided(by: 3)

        #expect(Money.Unrounded(bytes: typed.bytes) == Money(minorUnits: 10_00, currency: .gbp).unrounded.divided(by: 3))
    }

    @Test("Decoding as the wrong typed currency fails")
    func wrongTypedCurrencyIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let sterling = GBP(minorUnits: 4_99).unrounded.bytes

        #expect(EUR.Unrounded(bytes: sterling) == nil)
    }

    @Test("A scale byte outside zero to eighteen is refused")
    func outOfRangeScaleIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        var raw = Self.array(GBP(minorUnits: 4_99).unrounded.bytes)
        raw[22] = 19

        #expect(Money.Unrounded(bytes: Self.bytes(raw)) == nil)
    }

    @Test("An empty currency code is refused")
    func emptyCodeIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        var raw = Self.array(GBP(minorUnits: 4_99).unrounded.bytes)
        for index in 16 ... 21 {
            raw[index] = 0
        }

        #expect(Money.Unrounded(bytes: Self.bytes(raw)) == nil)
    }

    @Test("A shipped code at a scale it is not shipped at is refused")
    func shippedCodeAtWrongScaleIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        var raw = Self.array(GBP(minorUnits: 4_99).unrounded.bytes)
        raw[22] = 3   // GBP ships at two places, not three

        #expect(Money.Unrounded(bytes: Self.bytes(raw)) == nil)
    }

    // The convenience encodes a settled amount straight into the unrounded form, widening by 10^18 as it
    // goes. It must match materializing the `Unrounded` first, and read back as that same amount — proof
    // the widen is a genuine multiply, not a zero-pad into the low bytes.
    @Test("A settled amount's unroundedBytes match its unrounded encoding")
    func unroundedBytesMatchUnrounded() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let money = GBP(minorUnits: 4_99)

        #expect(Self.array(money.unroundedBytes) == Self.array(money.unrounded.bytes))
        #expect(GBP.Unrounded(bytes: money.unroundedBytes) == money.unrounded)
    }

    @Test("The convenience works for a runtime currency too")
    func unroundedBytesRuntime() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let money = Money(minorUnits: 4_99, currency: .gbp)

        #expect(Money.Unrounded(bytes: money.unroundedBytes) == money.unrounded)
    }

    // Pins the wire format. The amount is 1 × 10^18 (one whole pound's worth of the count, widened), so
    // its sixteen bytes are the well-known constant, not a bare 1 in the low byte.
    @Test("The bytes are amount, then code, then scale, big-endian")
    func layoutIsFixed() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let expected: [UInt8] = [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // Int128 10^18, big-endian: high 8 bytes
            0x0D, 0xE0, 0xB6, 0xB3, 0xA7, 0x64, 0x00, 0x00,  // low 8 bytes (1e18 = 0x0DE0B6B3A7640000)
            0x1C, 0x24, 0x00, 0x00, 0x00, 0x00,              // "GBP", six-bit packed
            0x02,                                            // two decimal places
        ]

        #expect(Self.array(GBP(minorUnits: 1).unrounded.bytes) == expected)
    }
}

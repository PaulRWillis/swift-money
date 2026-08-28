import SwiftMoneyCore
import Testing

// The byte serializer exists only where `InlineArray` does (macOS 26 and up). The suite itself is not
// annotated — `@Test` cannot sit on an availability-limited function — so each test guards with
// `#available` and no-ops on older systems, where there is no serializer to exercise.
@Suite("Money byte serialization")
struct MoneyBytesTests {

    // Every ISO scale in circulation plus the two crypto scales, as (code, scale-in-minor-units).
    static let scales: [(code: CurrencyCode, unitScale: UnitScale)] = [
        ("JPY", 1),                          // no minor unit
        ("GBP", 100),                        // the common hundredth
        ("KWD", 1_000),                      // three places
        ("CLF", 10_000),                     // four places, the finest ISO reaches
        ("BTC", 100_000_000),                // eight places
        ("ETH", 1_000_000_000_000_000_000),  // eighteen places, the finest a scale reaches
    ]

    static let amounts: [Int64] = [0, 1, -1, 4_99, -4_99, 1_000_000, .max, .min]

    // A currency built from a code and scale that no test needs to be a shipped one.
    static func currency(_ code: CurrencyCode, _ scale: UnitScale) -> Currency {
        customCurrency(code: code, unitScale: scale)
    }

    // Turns the fixed encoding into an array so it can be compared and indexed in assertions.
    @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
    static func array(_ bytes: InlineArray<15, UInt8>) -> [UInt8] {
        var result: [UInt8] = []
        for index in 0 ..< bytes.count {
            result.append(bytes[index])
        }
        return result
    }

    // Builds the fixed encoding from fifteen bytes, for the corrupt-input and hand-built-layout tests.
    @available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
    static func bytes(_ raw: [UInt8]) -> InlineArray<15, UInt8> {
        precondition(raw.count == 15, "a money encoding is fifteen bytes")
        return InlineArray<15, UInt8> { raw[$0] }
    }

    @Test("An encoding is fifteen bytes")
    func encodingIsFifteenBytes() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        #expect(GBP.byteCount == 15)
        #expect(Money.byteCount == 15)
        #expect(Self.array(GBP(minorUnits: 4_99).bytes).count == 15)
    }

    @Test(
        "A runtime amount survives a round trip at every scale and sign",
        arguments: scales, amounts
    )
    func runtimeRoundTrip(_ scale: (code: CurrencyCode, unitScale: UnitScale), _ amount: Int64) {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let original = Money(minorUnits: amount, currency: Self.currency(scale.code, scale.unitScale))

        #expect(Money(bytes: original.bytes) == original)
    }

    @Test("A typed amount survives a round trip", arguments: amounts)
    func typedRoundTrip(_ amount: Int64) {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let original = GBP(minorUnits: amount)

        #expect(GBP(bytes: original.bytes) == original)
    }

    @Test("A typed amount and the same runtime amount encode identically")
    func typedAndRuntimeAgree() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let typed = GBP(minorUnits: 4_99)
        let runtime = Money(minorUnits: 4_99, currency: .gbp)

        #expect(Self.array(typed.bytes) == Self.array(runtime.bytes))
    }

    @Test("Typed bytes decode as the matching runtime amount")
    func typedDecodesAsRuntime() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let typed = GBP(minorUnits: 4_99)

        #expect(Money(bytes: typed.bytes) == Money(minorUnits: 4_99, currency: .gbp))
    }

    @Test("Runtime bytes decode as the matching typed amount")
    func runtimeDecodesAsTyped() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let runtime = Money(minorUnits: 4_99, currency: .gbp)

        #expect(GBP(bytes: runtime.bytes) == GBP(minorUnits: 4_99))
    }

    @Test("Decoding as the wrong typed currency fails")
    func wrongTypedCurrencyIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let sterling = GBP(minorUnits: 4_99).bytes

        #expect(EUR(bytes: sterling) == nil)
    }

    @Test("A scale byte outside zero to eighteen is refused")
    func outOfRangeScaleIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        var raw = Self.array(GBP(minorUnits: 4_99).bytes)
        raw[14] = 19

        #expect(Money(bytes: Self.bytes(raw)) == nil)
    }

    @Test("An empty currency code is refused")
    func emptyCodeIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        var raw = Self.array(GBP(minorUnits: 4_99).bytes)
        for index in 8 ... 13 {
            raw[index] = 0
        }

        #expect(Money(bytes: Self.bytes(raw)) == nil)
    }

    // A shipped code carries its own scale, so bytes pairing it with a different scale are corrupt: the
    // scale is a valid number of places, but not this currency's. The runtime decoder must reject them
    // rather than mint a second, incompatible sterling.
    @Test("A shipped code at a scale it is not shipped at is refused")
    func shippedCodeAtWrongScaleIsRefused() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        var raw = Self.array(GBP(minorUnits: 4_99).bytes)
        raw[14] = 3   // GBP ships at two places, not three

        #expect(Money(bytes: Self.bytes(raw)) == nil)
    }

    // Pins the wire format so a change to field order, width or endianness cannot pass silently.
    @Test("The bytes are amount, then code, then scale, big-endian")
    func layoutIsFixed() {
        guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *) else { return }

        let expected: [UInt8] = [
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0xF3,  // Int64 499, big-endian
            0x1C, 0x24, 0x00, 0x00, 0x00, 0x00,              // "GBP", six-bit packed
            0x02,                                            // two decimal places
        ]

        #expect(Self.array(GBP(minorUnits: 4_99).bytes) == expected)
    }
}

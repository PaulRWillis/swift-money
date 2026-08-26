// A base-10 fixed-point number with 18 fractional digits, backed by `Int128`.
//
// The value is `raw / 10^18`, so 0.05 is stored as `raw == 50_000_000_000_000_000`. This is the internal
// precision engine for fractional money; it knows nothing of currency or minor units.
package struct Fixed: Equatable, Hashable, Sendable, BitwiseCopyable {
    // The value scaled by `scale`: value × 10^18.
    package let raw: Int128

    // The number of fractional digits a value is held to.
    package static let fractionalDigits = 18

    // The scaling factor: ten to the `fractionalDigits`.
    package static let scale: Int128 = 1_000_000_000_000_000_000

    package static let zero = Fixed(raw: 0)

    package init(raw: Int128) {
        self.raw = raw
    }
}

extension Fixed: Comparable {
    package static func < (lhs: Fixed, rhs: Fixed) -> Bool {
        lhs.raw < rhs.raw
    }
}

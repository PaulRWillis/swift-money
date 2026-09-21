import SwiftMoneyLocalization

// A byte builder for hand-building blob sections in tests, so a test writes exactly what BlobReader
// reads: integers as printable digits, strings appended to the pool. `pool` returns the reference to
// the string it appended.
struct BlobTestBuilder {
    var bytes: [UInt8] = []

    // Where these bytes begin in the finished blob, so a section built after a header that is written
    // later still records the offsets a reader will use.
    let base: Int

    var count: Int { base + bytes.count }

    init(base: Int = 0) {
        self.base = base
    }

    mutating func digits(_ value: UInt64, width: Int) {
        for position in stride(from: width - 1, through: 0, by: -1) {
            let digit = UInt8(truncatingIfNeeded: value >> (position * BlobDigits.bits)) & 0b11_1111
            bytes.append(BlobDigits.digit(for: digit))
        }
    }

    mutating func u8(_ value: UInt8) { digits(UInt64(value), width: BlobDigits.u8) }
    mutating func u16(_ value: UInt16) { digits(UInt64(value), width: BlobDigits.u16) }
    mutating func u32(_ value: UInt32) { digits(UInt64(value), width: BlobDigits.u32) }
    mutating func u64(_ value: UInt64) { digits(value, width: BlobDigits.u64) }
    mutating func ref(_ ref: StringRef) { u32(ref.offset); u32(ref.length) }

    mutating func pool(_ string: String) -> StringRef {
        let ref = StringRef(offset: UInt32(count), length: UInt32(string.utf8.count))
        bytes.append(contentsOf: string.utf8)
        return ref
    }
}

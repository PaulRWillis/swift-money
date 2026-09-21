import SwiftMoneyLocalization

// A little-endian byte builder for hand-building blob sections in tests, so a test writes exactly what
// BlobReader reads. `pool` appends a string and returns its reference.
struct BlobTestBuilder {
    var bytes: [UInt8] = []
    var count: Int { bytes.count }

    mutating func u8(_ value: UInt8) { bytes.append(value) }
    mutating func u16(_ value: UInt16) { u8(UInt8(value & 0xFF)); u8(UInt8(value >> 8)) }
    mutating func u32(_ value: UInt32) { for shift in stride(from: 0, to: 32, by: 8) { u8(UInt8((value >> shift) & 0xFF)) } }
    mutating func u64(_ value: UInt64) { for shift in stride(from: 0, to: 64, by: 8) { u8(UInt8((value >> shift) & 0xFF)) } }
    mutating func ref(_ ref: StringRef) { u32(ref.offset); u32(ref.length) }

    mutating func pool(_ string: String) -> StringRef {
        let ref = StringRef(offset: UInt32(count), length: UInt32(string.utf8.count))
        bytes.append(contentsOf: string.utf8)
        return ref
    }
}

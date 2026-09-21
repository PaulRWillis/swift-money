/// A Foundation-free cursor over the packed table bytes, so this module still compiles under Embedded:
/// little-endian fixed-width integers and UTF-8 strings sliced from a static byte buffer. Offsets are
/// written by the generator, so reads are not bounds-checked.
@usableFromInline
package struct BlobReader {
    @usableFromInline let base: UnsafePointer<UInt8>
    @usableFromInline let count: Int

    @usableFromInline
    package init(base: UnsafePointer<UInt8>, count: Int) {
        self.base = base
        self.count = count
    }

    /// The byte at `offset`.
    @usableFromInline
    package func u8(at offset: Int) -> UInt8 {
        base[offset]
    }

    /// The little-endian `UInt16` at `offset`.
    @usableFromInline
    package func u16(at offset: Int) -> UInt16 {
        UInt16(base[offset]) | (UInt16(base[offset + 1]) << 8)
    }

    /// The little-endian `UInt32` at `offset`.
    @usableFromInline
    package func u32(at offset: Int) -> UInt32 {
        UInt32(base[offset])
            | (UInt32(base[offset + 1]) << 8)
            | (UInt32(base[offset + 2]) << 16)
            | (UInt32(base[offset + 3]) << 24)
    }

    /// The little-endian `UInt64` at `offset`.
    @usableFromInline
    package func u64(at offset: Int) -> UInt64 {
        UInt64(u32(at: offset)) | (UInt64(u32(at: offset + 4)) << 32)
    }

    /// The ``StringRef`` (offset then length, each little-endian `UInt32`) at `offset`.
    @usableFromInline
    package func stringRef(at offset: Int) -> StringRef {
        StringRef(offset: u32(at: offset), length: u32(at: offset + 4))
    }

    /// The string a ``StringRef`` points at, decoded from the pool's UTF-8 bytes.
    @usableFromInline
    package func string(_ ref: StringRef) -> String {
        guard ref.length > 0 else { return "" }
        let slice = UnsafeBufferPointer(start: base + Int(ref.offset), count: Int(ref.length))
        return String(decoding: slice, as: UTF8.self)
    }

    /// The byte offset of the fixed-`stride` record whose leading little-endian `UInt64` equals `code`,
    /// among `count` records from `start`, by binary search; `nil` if none. Records must be sorted
    /// ascending by that leading code.
    package func recordOffset(code: UInt64, start: Int, count: Int, stride: Int) -> Int? {
        var low = 0
        var high = count

        while low < high {
            let mid = (low + high) / 2
            let offset = start + mid * stride
            let value = u64(at: offset)
            if value == code {
                return offset
            } else if value < code {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return nil
    }
}

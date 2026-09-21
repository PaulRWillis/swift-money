/// A Foundation-free cursor over the packed table bytes, so this module still compiles under Embedded:
/// integers written as ``BlobDigits`` and strings sliced from the pool by offset and length.
///
/// The bytes are a `StaticString` the generator wrote, so reads are not bounds-checked and a digit run
/// always holds the field it is read as.
///
/// The reader is `Sendable` because it points at a string literal: static, read-only bytes that outlive
/// every use of them.
@usableFromInline
package struct BlobReader: @unchecked Sendable {
    @usableFromInline let base: UnsafePointer<UInt8>
    @usableFromInline let count: Int

    @usableFromInline
    package init(base: UnsafePointer<UInt8>, count: Int) {
        self.base = base
        self.count = count
    }

    /// The raw byte at `offset`, as the blob holds it: one digit of an integer, or one byte of the
    /// pool's UTF-8.
    @usableFromInline
    package func byte(at offset: Int) -> UInt8 {
        base[offset]
    }

    /// The integer written as `width` digits at `offset`, most significant first.
    ///
    /// Eleven digits carry 66 bits, two more than the widest integer the tables hold, so the leading
    /// digit of a `UInt64` field carries four bits and the excess is never written.
    @usableFromInline
    package func integer(at offset: Int, width: Int) -> UInt64 {
        assert(offset >= 0 && offset + width <= count, "read past the packed tables")

        var value: UInt64 = 0

        for position in 0 ..< width {
            value = value << BlobDigits.bits | UInt64(BlobDigits.value(of: base[offset + position]))
        }

        return value
    }

    /// The `UInt8` at `offset`.
    @usableFromInline
    package func u8(at offset: Int) -> UInt8 {
        UInt8(truncatingIfNeeded: integer(at: offset, width: BlobDigits.u8))
    }

    /// The `UInt16` at `offset`.
    @usableFromInline
    package func u16(at offset: Int) -> UInt16 {
        UInt16(truncatingIfNeeded: integer(at: offset, width: BlobDigits.u16))
    }

    /// The `UInt32` at `offset`.
    @usableFromInline
    package func u32(at offset: Int) -> UInt32 {
        UInt32(truncatingIfNeeded: integer(at: offset, width: BlobDigits.u32))
    }

    /// The `UInt64` at `offset`.
    @usableFromInline
    package func u64(at offset: Int) -> UInt64 {
        integer(at: offset, width: BlobDigits.u64)
    }

    /// The ``StringRef`` (an offset then a length) at `offset`.
    @usableFromInline
    package func stringRef(at offset: Int) -> StringRef {
        StringRef(offset: u32(at: offset), length: u32(at: offset + BlobDigits.u32))
    }

    /// The string a ``StringRef`` points at, decoded from the pool's UTF-8 bytes.
    @usableFromInline
    package func string(_ ref: StringRef) -> String {
        guard ref.length > 0 else { return "" }

        assert(Int(ref.offset) + Int(ref.length) <= count, "read past the packed tables")

        let slice = UnsafeBufferPointer(start: base + Int(ref.offset), count: Int(ref.length))

        return String(decoding: slice, as: UTF8.self)
    }

    /// The byte offset of the fixed-`stride` record whose leading `UInt64` equals `code`, among `count`
    /// records from `start`, by binary search; `nil` if none. Records must be sorted ascending by that
    /// leading code.
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

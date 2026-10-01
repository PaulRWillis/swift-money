/// A Foundation-free cursor over the packed table bytes, so this module still compiles under Embedded:
/// integers written as ``BlobDigits`` and strings sliced from the pool by offset and length.
///
/// The bytes are a `StaticString` the generator wrote, and a digit run always holds the field it is
/// read as. Every read is bounds-checked with `precondition`, which stays active in release builds
/// (including Embedded release builds), so a generator bug or a hand-edited blob traps instead of
/// reading past the buffer.
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
        precondition(offset >= 0 && offset < count, "read past the packed tables")

        return base[offset]
    }

    /// The integer written as `width` digits at `offset`, most significant first.
    ///
    /// Eleven digits carry 66 bits, two more than the widest integer the tables hold, so the leading
    /// digit of a `UInt64` field carries four bits and the excess is never written.
    @usableFromInline
    package func integer(at offset: Int, width: Int) -> UInt64 {
        precondition(offset >= 0 && offset + width <= count, "read past the packed tables")

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

    /// The blob offset written as ``BlobDigits/offset`` digits at `position`.
    @usableFromInline
    package func offsetField(at position: Int) -> Int {
        Int(integer(at: position, width: BlobDigits.offset))
    }

    /// The ``StringRef`` (an offset then a length) at `offset`.
    @usableFromInline
    package func stringRef(at offset: Int) -> StringRef {
        StringRef(
            offset: UInt32(truncatingIfNeeded: integer(at: offset, width: BlobDigits.offset)),
            length: UInt32(truncatingIfNeeded: integer(at: offset + BlobDigits.offset, width: BlobDigits.length))
        )
    }

    /// The string a ``StringRef`` points at, decoded from the pool's UTF-8 bytes.
    @usableFromInline
    package func string(_ ref: StringRef) -> String {
        guard ref.length > 0 else { return "" }

        precondition(Int(ref.offset) + Int(ref.length) <= count, "read past the packed tables")

        let slice = UnsafeBufferPointer(start: base + Int(ref.offset), count: Int(ref.length))

        return String(decoding: slice, as: UTF8.self)
    }

    /// Returns the offset of the record filed under a currency code, or `nil` if there is none.
    ///
    /// Searches `count` records of `stride` bytes from `start`, each opening with its code, and sorted
    /// in ``Localization/CurrencyCode`` order.
    ///
    /// ```swift
    /// // Two records of a code alone, EUR then GBP; `gbp` and `usd` are Localization.CurrencyCode values.
    /// reader.recordOffset(of: gbp, start: 0, count: 2, stride: 3)   // 3
    /// reader.recordOffset(of: usd, start: 0, count: 2, stride: 3)   // nil
    /// ```
    ///
    /// - Parameters:
    ///   - code: The currency code to find.
    ///   - start: The offset of the first record.
    ///   - count: How many records there are.
    ///   - stride: How many bytes each record takes.
    /// - Returns: The offset of the record whose code is `code`, or `nil` if no record has it.
    /// - Precondition: Every record the search reads must lie inside the packed tables.
    /// - Complexity: O(log *n*), where *n* is `count`.
    // Forced inline: an outlined copy adds a call to every currency lookup.
    @inline(__always)
    package func recordOffset(
        of code: Localization.CurrencyCode, start: Int, count: Int, stride: Int
    ) -> Int? {
        recordOffset(
            code: code.value, codeWidth: Localization.CurrencyCode.digitCount,
            start: start, count: count, stride: stride
        )
    }

    /// Returns the offset of the record whose leading key equals `code`, or `nil` if there is none.
    ///
    /// Searches `count` records of `stride` bytes from `start`, sorted ascending by that key.
    ///
    /// - Parameters:
    ///   - code: The key to find.
    ///   - codeWidth: How many digits the key takes.
    ///   - start: The offset of the first record.
    ///   - count: How many records there are.
    ///   - stride: How many bytes each record takes.
    /// - Returns: The offset of the record whose key is `code`, or `nil` if no record has it.
    /// - Precondition: Every record the search reads must lie inside the packed tables.
    /// - Complexity: O(log *n*), where *n* is `count`.
    private func recordOffset(code: UInt64, codeWidth: Int, start: Int, count: Int, stride: Int) -> Int? {
        var low = 0
        var high = count

        while low < high {
            let mid = (low + high) / 2
            let offset = start + mid * stride
            let order = compareCode(at: offset, to: code, width: codeWidth)
            if order == 0 {
                return offset
            } else if order < 0 {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return nil
    }

    /// The record's `width`-digit code at `offset` compared to `code`: negative if the record's is
    /// smaller, positive if larger, zero if equal.
    ///
    /// Compares the stored digits against the code re-encoded a digit at a time rather than decoding the
    /// record's into an integer: the alphabet is order-preserving and the width fixed, so digit order is
    /// integer order, and a probe stops at the first digit that differs instead of reading all of them.
    private func compareCode(at offset: Int, to code: UInt64, width: Int) -> Int {
        precondition(offset >= 0 && offset + width <= count, "read past the packed tables")

        for position in 0 ..< width {
            let shift = (width - 1 - position) * BlobDigits.bits
            let queryDigit = BlobDigits.digit(for: UInt8(truncatingIfNeeded: code >> shift))
            let recordDigit = base[offset + position]
            if recordDigit != queryDigit {
                return recordDigit < queryDigit ? -1 : 1
            }
        }

        return 0
    }
}

import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The Foundation-free byte reader under the compact CLDR blob: integers written as printable digits and
// pooled UTF-8 strings sliced by offset and length — the primitives every decoded record is built from.
@Suite("Blob Reader Tests")
struct BlobReaderTests {

    static func withReader(_ bytes: [UInt8], _ body: (BlobReader) -> Void) {
        bytes.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else {
                Issue.record("a non-empty array has a base address")
                return
            }
            body(BlobReader(base: base, count: buffer.count))
        }
    }

    // Pins the encoding as text rather than only by round trip: 42 fits one digit, so a two-digit field
    // holding it reads as a zero digit and then 42's own.
    @Test("An integer is written as digits, most significant first")
    func integersAreWrittenAsDigits() {
        var builder = BlobTestBuilder()
        builder.u8(42)

        #expect(String(decoding: builder.bytes, as: UTF8.self) == "-e")
        #expect(builder.count == BlobDigits.u8)
    }

    @Test("Reads back each integer width")
    func integerWidths() {
        var builder = BlobTestBuilder()
        builder.u8(42)
        builder.u16(513)
        builder.u32(65_536)

        Self.withReader(builder.bytes) { reader in
            #expect(reader.u8(at: 0) == 42)
            #expect(reader.u16(at: BlobDigits.u8) == 513)
            #expect(reader.u32(at: BlobDigits.u8 + BlobDigits.u16) == 65_536)
        }
    }

    // The widths are one digit wider than the integer needs, so the top of each range is where an
    // off-by-one width would show.
    @Test("Reads back the widest value of each width")
    func widestValues() {
        var builder = BlobTestBuilder()
        builder.u8(.max)
        builder.u16(.max)
        builder.u32(.max)
        builder.u64(.max)

        Self.withReader(builder.bytes) { reader in
            #expect(reader.u8(at: 0) == .max)
            #expect(reader.u16(at: BlobDigits.u8) == .max)
            #expect(reader.u32(at: BlobDigits.u8 + BlobDigits.u16) == .max)
            #expect(reader.u64(at: BlobDigits.u8 + BlobDigits.u16 + BlobDigits.u32) == .max)
        }
    }

    @Test("Slices pooled strings by offset and length")
    func pooledStrings() {
        var builder = BlobTestBuilder()
        let hello = builder.pool("hello")
        let world = builder.pool("world")

        Self.withReader(builder.bytes) { reader in
            #expect(reader.string(hello) == "hello")
            #expect(reader.string(world) == "world")
            #expect(reader.byte(at: Int(world.offset)) == UInt8(ascii: "w"))
        }
    }

    @Test("Reads a reference written into a record")
    func stringReferences() {
        var builder = BlobTestBuilder()
        let hello = builder.pool("hello")
        let record = builder.count
        builder.ref(hello)

        Self.withReader(builder.bytes) { reader in
            #expect(reader.stringRef(at: record) == hello)
            #expect(reader.string(reader.stringRef(at: record)) == "hello")
        }
    }

    @Test("A zero-length reference yields the empty string without touching the pool")
    func emptyReference() {
        var builder = BlobTestBuilder()
        _ = builder.pool("unused")

        Self.withReader(builder.bytes) { reader in
            #expect(reader.string(.empty) == "")
            #expect(reader.string(StringRef(offset: 999, length: 0)) == "")
        }
    }

    // An exit test's body is spawned as a fresh process, so it may not capture anything from outside
    // itself: every value the body needs is built inside it.

    @Test("Reading an integer past the packed bytes traps")
    func integerPastBoundsTraps() async {
        await #expect(processExitsWith: .failure) {
            var builder = BlobTestBuilder()
            builder.u8(42)

            Self.withReader(builder.bytes) { reader in
                _ = reader.u8(at: BlobDigits.u8)
            }
        }
    }

    @Test("Reading a string reference past the packed bytes traps")
    func stringPastBoundsTraps() async {
        await #expect(processExitsWith: .failure) {
            var builder = BlobTestBuilder()
            _ = builder.pool("hello")

            Self.withReader(builder.bytes) { reader in
                _ = reader.string(StringRef(offset: 999, length: 1))
            }
        }
    }

    @Test("Searching past the packed bytes traps")
    func recordSearchPastBoundsTraps() async {
        await #expect(processExitsWith: .failure) {
            var builder = BlobTestBuilder()
            builder.u64(10)

            Self.withReader(builder.bytes) { reader in
                _ = reader.recordOffset(
                    code: 10, codeWidth: BlobDigits.u64, start: 0, count: 4, stride: BlobDigits.u64
                )
            }
        }
    }

    @Test("Finds a record by its leading code, and reports a code it has none for")
    func recordSearch() {
        var builder = BlobTestBuilder()
        let codes: [UInt64] = [10, 20, 30, 40]
        let start = builder.count
        for code in codes {
            builder.u64(code)
        }

        Self.withReader(builder.bytes) { reader in
            for (index, code) in codes.enumerated() {
                let offset = reader.recordOffset(
                    code: code, codeWidth: BlobDigits.u64, start: start, count: codes.count, stride: BlobDigits.u64
                )
                #expect(offset == start + index * BlobDigits.u64)
            }

            #expect(reader.recordOffset(
                code: 25, codeWidth: BlobDigits.u64, start: start, count: codes.count, stride: BlobDigits.u64
            ) == nil)
        }
    }
}

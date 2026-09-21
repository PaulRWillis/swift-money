import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

// The Foundation-free byte reader under the compact CLDR blob. Little-endian ints and pooled UTF-8
// strings sliced by offset+length — the primitives every decoded record is built from.
@Suite("Blob Reader Tests")
struct BlobReaderTests {

    // Bytes: [0]=0x2A; [1..2]=0x0102 LE (513); [3..6]=0x00010000 LE (65536); pool "helloworld" at [7];
    // then at [17] a StringRef record (offset 7, length 5) as two little-endian UInt32s.
    static let bytes: [UInt8] = [
        0x2A,
        0x01, 0x02,
        0x00, 0x00, 0x01, 0x00,
    ] + Array("helloworld".utf8) + [
        0x07, 0x00, 0x00, 0x00,
        0x05, 0x00, 0x00, 0x00,
    ]

    static func withReader(_ body: (BlobReader) -> Void) {
        Self.bytes.withUnsafeBufferPointer { buffer in
            body(BlobReader(base: buffer.baseAddress!, count: buffer.count))
        }
    }

    @Test("Reads fixed-width little-endian integers")
    func fixedWidthIntegers() {
        Self.withReader { reader in
            #expect(reader.u8(at: 0) == 0x2A)
            #expect(reader.u16(at: 1) == 513)
            #expect(reader.u32(at: 3) == 65_536)
        }
    }

    @Test("Slices pooled strings by offset and length")
    func pooledStrings() {
        Self.withReader { reader in
            let poolStart: UInt32 = 7
            #expect(reader.string(StringRef(offset: poolStart, length: 5)) == "hello")
            #expect(reader.string(StringRef(offset: poolStart + 5, length: 5)) == "world")
        }
    }

    @Test("Reads a UInt64 and a StringRef record")
    func wideReads() {
        Self.withReader { reader in
            #expect(reader.u64(at: 17) == 0x0000_0005_0000_0007)
            let ref = reader.stringRef(at: 17)
            #expect(ref == StringRef(offset: 7, length: 5))
            #expect(reader.string(ref) == "hello")
        }
    }

    @Test("A zero-length reference yields the empty string without touching the pool")
    func emptyReference() {
        Self.withReader { reader in
            #expect(reader.string(.empty) == "")
            #expect(reader.string(StringRef(offset: 999, length: 0)) == "")
        }
    }
}

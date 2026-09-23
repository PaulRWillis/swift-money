import SwiftMoneyLocalization

// Writes the bytes of the packed tables: every integer as the printable digits `BlobReader` decodes,
// most significant first. The runtime reads this format and never writes it, so the writer lives here
// beside the generator rather than in the library; the golden digests prove the two agree.
struct BlobWriter {
    private(set) var bytes: [UInt8] = []

    // Where these bytes begin in the finished blob, so an offset recorded while writing is the offset a
    // reader will use. The sections are written after the header, which is only sized until then.
    private let base: Int

    // Where the next byte written will land.
    var offset: Int { base + bytes.count }

    init(base: Int) {
        self.base = base
    }

    mutating func digits(_ value: UInt64, width: Int) {
        for position in stride(from: width - 1, through: 0, by: -1) {
            bytes.append(BlobDigits.digit(for: UInt8(truncatingIfNeeded: value >> (position * BlobDigits.bits))))
        }
    }

    mutating func u8(_ value: UInt8) { digits(UInt64(value), width: BlobDigits.u8) }
    mutating func u16(_ value: UInt16) { digits(UInt64(value), width: BlobDigits.u16) }
    mutating func u32(_ value: Int) { digits(UInt64(value), width: BlobDigits.u32) }
    mutating func u64(_ value: UInt64) { digits(value, width: BlobDigits.u64) }
    mutating func currencyCode(_ compactValue: UInt64) {
        guard let wire = BlobDigits.currencyCodeWire(compactValue) else {
            preconditionFailure("currency code is not exactly \(BlobDigits.currencyCode) symbols")
        }
        digits(wire, width: BlobDigits.currencyCode)
    }

    mutating func offsetField(_ value: Int) {
        precondition(
            UInt64(value) < (UInt64(1) << (BlobDigits.offset * BlobDigits.bits)),
            "blob offset \(value) does not fit its field"
        )
        digits(UInt64(value), width: BlobDigits.offset)
    }

    mutating func ref(_ ref: StringRef) {
        offsetField(Int(ref.offset))
        precondition(
            UInt64(ref.length) < (UInt64(1) << (BlobDigits.length * BlobDigits.bits)),
            "string length \(ref.length) does not fit its field"
        )
        digits(UInt64(ref.length), width: BlobDigits.length)
    }

    mutating func append(_ raw: [UInt8]) {
        bytes.append(contentsOf: raw)
    }
}

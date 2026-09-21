import SwiftMoneyCore

/// The currency-full-name section of the packed blob: per locale, the currencies it names, each with an
/// `other` name and any per-category overrides.
///
/// Byte layout (all integers little-endian; `StringRef` is offset then length, two `UInt32`s):
/// - **directory** — `localeCount` entries of `recordsStart: UInt32`, `recordCount: UInt16` (stride 6),
///   indexed by locale.
/// - **records** — per locale, `recordCount` fixed records **sorted by** `CurrencyCode.packedValue`,
///   each: `code: UInt64`, `other: StringRef`, `overridesStart: UInt32`, `overrideCount: UInt8`
///   (stride 21). Sorted so a currency is found by binary search.
/// - **overrides** — `overrideCount` entries of `category: UInt8` (a ``PluralCategory/blobCode``),
///   `name: StringRef` (stride 9).
package struct CurrencyFullNameTable {
    let reader: BlobReader
    let directoryOffset: Int

    static let directoryStride = 6
    static let recordStride = 21
    static let overrideStride = 9

    package init(reader: BlobReader, directoryOffset: Int) {
        self.reader = reader
        self.directoryOffset = directoryOffset
    }

    /// What `code` is called in the locale at `localeIndex`, or `nil` if the blob does not name it there.
    package func name(localeIndex: Int, code: CurrencyCode) -> CurrencyFullName? {
        let entry = directoryOffset + localeIndex * Self.directoryStride
        let recordsStart = Int(reader.u32(at: entry))
        let recordCount = Int(reader.u16(at: entry + 4))

        guard let record = reader.recordOffset(
            code: code.packedValue, start: recordsStart, count: recordCount, stride: Self.recordStride
        ) else {
            return nil
        }

        let other = reader.string(reader.stringRef(at: record + 8))
        let overridesStart = Int(reader.u32(at: record + 16))
        let overrideCount = Int(reader.u8(at: record + 20))

        var byCategory: [PluralCategory: String] = [:]
        for index in 0 ..< overrideCount {
            let entry = overridesStart + index * Self.overrideStride
            guard let category = PluralCategory(blobCode: reader.u8(at: entry)) else { continue }
            byCategory[category] = reader.string(reader.stringRef(at: entry + 1))
        }

        return CurrencyFullName(other: other, byCategory: byCategory)
    }
}

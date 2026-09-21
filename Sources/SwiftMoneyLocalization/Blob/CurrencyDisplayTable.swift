import SwiftMoneyCore

/// The currency-display section of the packed blob: per locale, the currencies whose symbol differs from
/// their code, each with a standard and narrow symbol and their spacings.
///
/// Byte layout (little-endian; `StringRef` is offset then length):
/// - **directory** — `localeCount` entries of `recordsStart: UInt32`, `recordCount: UInt16` (stride 6).
/// - **records** — per locale, `recordCount` records **sorted by** `CurrencyCode.packedValue`, each:
///   `code: UInt64`, then four `StringRef`s — `standardSymbol`, `standardSpacing`, `narrowSymbol`,
///   `narrowSpacing` (stride 40).
package struct CurrencyDisplayTable {
    let reader: BlobReader
    let directoryOffset: Int

    static let directoryStride = 6
    static let recordStride = 40

    package init(reader: BlobReader, directoryOffset: Int) {
        self.reader = reader
        self.directoryOffset = directoryOffset
    }

    /// How `code` is displayed in the locale at `localeIndex`, or `nil` if it has no distinct symbol
    /// there (the caller then falls back to the code).
    package func display(localeIndex: Int, code: CurrencyCode) -> CurrencyDisplay? {
        let entry = directoryOffset + localeIndex * Self.directoryStride
        let recordsStart = Int(reader.u32(at: entry))
        let recordCount = Int(reader.u16(at: entry + 4))

        guard let record = reader.recordOffset(
            code: code.packedValue, start: recordsStart, count: recordCount, stride: Self.recordStride
        ) else {
            return nil
        }

        return CurrencyDisplay(
            standardSymbol: reader.string(reader.stringRef(at: record + 8)),
            standardSpacing: reader.string(reader.stringRef(at: record + 16)),
            narrowSymbol: reader.string(reader.stringRef(at: record + 24)),
            narrowSpacing: reader.string(reader.stringRef(at: record + 32))
        )
    }
}

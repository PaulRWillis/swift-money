import SwiftMoneyCore

/// The currency-display section of the packed blob: per locale, the currencies whose symbol differs from
/// their code, each with a standard and narrow symbol and their spacings.
///
/// Every integer is written as ``BlobDigits``, so a field's position is the width of the fields before
/// it. The section is a **directory** of one entry per locale, indexed by ``LocaleIndex``, and the
/// **records** it points at, sorted by ``CurrencyCode/packedValue`` so a currency is found by binary
/// search.
package struct CurrencyDisplayTable: Sendable {
    let reader: BlobReader
    let directoryOffset: Int

    private enum Entry {
        static let recordsStart = 0
        static let recordCount = recordsStart + BlobDigits.u32
        static let stride = recordCount + BlobDigits.u16
    }

    private enum Record {
        static let code = 0
        static let standardSymbol = code + BlobDigits.u64
        static let standardSpacing = standardSymbol + BlobDigits.stringRef
        static let narrowSymbol = standardSpacing + BlobDigits.stringRef
        static let narrowSpacing = narrowSymbol + BlobDigits.stringRef
        static let stride = narrowSpacing + BlobDigits.stringRef
    }

    package init(reader: BlobReader, directoryOffset: Int) {
        self.reader = reader
        self.directoryOffset = directoryOffset
    }

    /// How `code` is displayed in the locale at `localeIndex`, or `nil` if it has no distinct symbol
    /// there (the caller then falls back to the code).
    package func display(localeIndex: LocaleIndex, code: CurrencyCode) -> CurrencyDisplay? {
        let entry = directoryOffset + localeIndex.position * Entry.stride
        let recordsStart = Int(reader.u32(at: entry + Entry.recordsStart))
        let recordCount = Int(reader.u16(at: entry + Entry.recordCount))

        guard let record = reader.recordOffset(
            code: code.packedValue, start: recordsStart, count: recordCount, stride: Record.stride
        ) else {
            return nil
        }

        return CurrencyDisplay(
            standardSymbol: reader.string(reader.stringRef(at: record + Record.standardSymbol)),
            standardSpacing: reader.string(reader.stringRef(at: record + Record.standardSpacing)),
            narrowSymbol: reader.string(reader.stringRef(at: record + Record.narrowSymbol)),
            narrowSpacing: reader.string(reader.stringRef(at: record + Record.narrowSpacing))
        )
    }
}

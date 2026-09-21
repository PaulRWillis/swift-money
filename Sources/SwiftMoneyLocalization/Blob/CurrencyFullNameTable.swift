import SwiftMoneyCore

/// The currency-full-name section of the packed blob: per locale, the currencies it names, each with an
/// `other` name and any per-category overrides.
///
/// Every integer is written as ``BlobDigits``, so a field's position is the width of the fields before
/// it. The section is three runs:
/// - a **directory** of one entry per locale, holding where that locale's records start and how many
///   there are, indexed by ``LocaleIndex``;
/// - the **records**, per locale, sorted by ``CurrencyCode/packedValue`` so a currency is found by
///   binary search;
/// - the **overrides** a record points at, one per category that names the currency differently.
package struct CurrencyFullNameTable: Sendable {
    let reader: BlobReader
    let directoryOffset: Int

    private enum Entry {
        static let recordsStart = 0
        static let recordCount = recordsStart + BlobDigits.u32
        static let stride = recordCount + BlobDigits.u16
    }

    private enum Record {
        static let code = 0
        static let other = code + BlobDigits.u64
        static let overridesStart = other + BlobDigits.stringRef
        static let overrideCount = overridesStart + BlobDigits.u32
        static let stride = overrideCount + BlobDigits.u8
    }

    private enum Override {
        static let category = 0
        static let name = category + BlobDigits.u8
        static let stride = name + BlobDigits.stringRef
    }

    package init(reader: BlobReader, directoryOffset: Int) {
        self.reader = reader
        self.directoryOffset = directoryOffset
    }

    /// What `code` is called in the locale at `localeIndex`, or `nil` if the blob does not name it there.
    package func name(localeIndex: LocaleIndex, code: CurrencyCode) -> CurrencyFullName? {
        let entry = directoryOffset + localeIndex.position * Entry.stride
        let recordsStart = Int(reader.u32(at: entry + Entry.recordsStart))
        let recordCount = Int(reader.u16(at: entry + Entry.recordCount))

        guard let record = reader.recordOffset(
            code: code.packedValue, start: recordsStart, count: recordCount, stride: Record.stride
        ) else {
            return nil
        }

        let other = reader.string(reader.stringRef(at: record + Record.other))
        let overridesStart = Int(reader.u32(at: record + Record.overridesStart))
        let overrideCount = Int(reader.u8(at: record + Record.overrideCount))

        var byCategory: [PluralCategory: String] = [:]
        for index in 0 ..< overrideCount {
            let override = overridesStart + index * Override.stride
            guard let category = PluralCategory(blobCode: reader.u8(at: override + Override.category)) else {
                continue
            }
            byCategory[category] = reader.string(reader.stringRef(at: override + Override.name))
        }

        return CurrencyFullName(other: other, byCategory: byCategory)
    }
}

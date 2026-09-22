import SwiftMoneyCore

/// The currency-full-name section of the packed blob: per locale, the currencies it names, each with an
/// `other` name and any per-category overrides.
///
/// Every integer is written as ``BlobDigits``, so a field's position is the width of the fields before
/// it. The section is three runs:
/// - a **directory** of one entry per locale, holding where that locale's records start and how many
///   there are, indexed by ``LocaleIndex``;
/// - the **records**, per locale, sorted by ``CurrencyCode/compactValue`` so a currency is found by
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
        static let other = code + BlobDigits.currencyCode
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

    /// What `code` is called in the locale at `localeIndex` for one plural category, or `nil` if the blob
    /// does not name it there.
    ///
    /// Reads the one name a caller formatting an amount needs, where ``name(localeIndex:code:)`` builds
    /// every form the currency has and a dictionary to hold them.
    package func name(localeIndex: LocaleIndex, code: CurrencyCode, category: PluralCategory) -> String? {
        guard let record = recordOffset(localeIndex: localeIndex, code: code) else {
            return nil
        }

        let wanted = category.blobCode
        for override in overrides(of: record) where reader.u8(at: override + Override.category) == wanted {
            return reader.string(reader.stringRef(at: override + Override.name))
        }

        // Every category CLDR does not name separately takes the name it always publishes.
        return reader.string(reader.stringRef(at: record + Record.other))
    }

    /// What `code` is called in the locale at `localeIndex`, in every form it has there, or `nil` if the
    /// blob does not name it.
    package func name(localeIndex: LocaleIndex, code: CurrencyCode) -> CurrencyFullName? {
        guard let record = recordOffset(localeIndex: localeIndex, code: code) else {
            return nil
        }

        var byCategory: [PluralCategory: String] = [:]
        for override in overrides(of: record) {
            let code = reader.u8(at: override + Override.category)
            // The generator writes only valid codes, so a failure here is a generator bug, not input.
            guard let category = PluralCategory(blobCode: code) else {
                preconditionFailure("blob plural category code \(code) is unknown")  // coverage:ignore
            }
            byCategory[category] = reader.string(reader.stringRef(at: override + Override.name))
        }

        return CurrencyFullName(
            other: reader.string(reader.stringRef(at: record + Record.other)),
            byCategory: byCategory
        )
    }

    private func recordOffset(localeIndex: LocaleIndex, code: CurrencyCode) -> Int? {
        let entry = directoryOffset + localeIndex.position * Entry.stride

        return reader.recordOffset(
            code: code.compactValue,
            codeWidth: BlobDigits.currencyCode,
            start: Int(reader.u32(at: entry + Entry.recordsStart)),
            count: Int(reader.u16(at: entry + Entry.recordCount)),
            stride: Record.stride
        )
    }

    // Where each of a record's overrides begins.
    private func overrides(of record: Int) -> some Sequence<Int> {
        let start = Int(reader.u32(at: record + Record.overridesStart))
        let count = Int(reader.u8(at: record + Record.overrideCount))

        return (0 ..< count).lazy.map { start + $0 * Override.stride }
    }
}

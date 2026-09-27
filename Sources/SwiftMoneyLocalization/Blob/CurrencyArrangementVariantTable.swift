/// The currency-arrangement-variant section of the packed blob: the few per-locale rows where the
/// accounting presentation, the letter-adjacent symbol form, or both, arrange the currency differently
/// from the locale's standard arrangement.
///
/// Every integer is written as ``BlobDigits``. The section is a count followed by fixed records sorted
/// by ``LocaleIndex``, so a row is found by binary search. A locale whose three variants all equal its
/// standard arrangement contributes no row, so a lookup for one always misses — this mirrors
/// ``NumberingSystemOverrideTable``, the sibling sparse section for numbering-system separators.
package struct CurrencyArrangementVariantTable: Sendable {
    let reader: BlobReader
    let recordsOffset: Int

    /// How many variant rows the section holds.
    package let count: Int

    private enum Section {
        static let count = 0
        static let records = count + BlobDigits.u32
    }

    private enum Record {
        static let localeIndex = 0
        static let accountingArrangementIndex = localeIndex + BlobDigits.u16
        static let alphaArrangementIndex = accountingArrangementIndex + BlobDigits.u16
        static let alphaAccountingArrangementIndex = alphaArrangementIndex + BlobDigits.u16
        static let stride = alphaAccountingArrangementIndex + BlobDigits.u16
    }

    package init(reader: BlobReader, sectionOffset: Int) {
        self.reader = reader
        self.count = Int(reader.u32(at: sectionOffset + Section.count))
        self.recordsOffset = sectionOffset + Section.records
    }

    /// The raw interned arrangement indices the locale at `localeIndex` carries for its three variant
    /// cells, or `nil` when it has no row (every cell equals its standard arrangement).
    ///
    /// Each index still needs resolving against the locale's own `standardArrangementIndex`: an index
    /// equal to it means "no variant" for that one cell, an in-band sentinel resolved to `nil` at the
    /// decode boundary that holds both indices — `NumberFormatTable`, not this type, which never sees
    /// the locale's `standardArrangementIndex`.
    package func variants(
        localeIndex: LocaleIndex
    ) -> (accounting: UInt16, alpha: UInt16, alphaAccounting: UInt16)? {
        let target = UInt16(localeIndex.position)
        var low = 0
        var high = count

        while low < high {
            let middle = (low + high) / 2
            let base = recordsOffset + middle * Record.stride
            let key = reader.u16(at: base + Record.localeIndex)

            if key == target {
                return (
                    accounting: reader.u16(at: base + Record.accountingArrangementIndex),
                    alpha: reader.u16(at: base + Record.alphaArrangementIndex),
                    alphaAccounting: reader.u16(at: base + Record.alphaAccountingArrangementIndex)
                )
            } else if key < target {
                low = middle + 1
            } else {
                high = middle
            }
        }

        return nil
    }
}

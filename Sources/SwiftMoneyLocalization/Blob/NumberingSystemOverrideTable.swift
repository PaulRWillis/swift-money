import SwiftMoneyCore

/// The numbering-system override section of the packed blob: the few per-(locale × system) separator sets
/// that differ from a system's own default, for the systems that impose their own separators.
///
/// Every integer is written as ``BlobDigits``. The section is a count followed by fixed records sorted by
/// the composite key (``LocaleIndex``, ``SystemIndex``), so an override is found by binary search. A system
/// that reuses the locale's separators contributes no rows, so a lookup for one always misses.
package struct NumberingSystemOverrideTable: Sendable {
    let reader: BlobReader
    let recordsOffset: Int

    /// How many override rows the section holds.
    package let count: Int

    private enum Section {
        static let count = 0
        static let records = count + BlobDigits.u16
    }

    private enum Record {
        static let localeIndex = 0
        static let systemIndex = localeIndex + BlobDigits.u16
        static let decimalSeparator = systemIndex + BlobDigits.u8
        static let groupingSeparator = decimalSeparator + BlobDigits.stringRef
        static let minusSign = groupingSeparator + BlobDigits.stringRef
        static let stride = minusSign + BlobDigits.stringRef
    }

    package init(reader: BlobReader, sectionOffset: Int) {
        self.reader = reader
        self.count = Int(reader.u16(at: sectionOffset + Section.count))
        self.recordsOffset = sectionOffset + Section.records
    }

    /// The separators the locale at `localeIndex` writes the system at `systemIndex` with, when they differ
    /// from the system's own default; `nil` when there is no such override (the caller then uses the
    /// default).
    package func symbols(localeIndex: LocaleIndex, systemIndex: SystemIndex) -> NumberingSystemSymbols? {
        let target = (UInt16(localeIndex.position), UInt8(systemIndex.position))
        var low = 0
        var high = count

        while low < high {
            let middle = (low + high) / 2
            let base = recordsOffset + middle * Record.stride
            let key = (reader.u16(at: base + Record.localeIndex), reader.u8(at: base + Record.systemIndex))

            if key == target {
                return decode(at: base)
            } else if key < target {
                low = middle + 1
            } else {
                high = middle
            }
        }

        return nil
    }

    private func decode(at base: Int) -> NumberingSystemSymbols {
        let decimal = reader.string(reader.stringRef(at: base + Record.decimalSeparator))
        let groupingRaw = reader.string(reader.stringRef(at: base + Record.groupingSeparator))
        let minus = reader.string(reader.stringRef(at: base + Record.minusSign))

        // The generator writes a non-empty grouping separator for every override row.
        guard let grouping = GroupingSeparator(groupingRaw) else {
            preconditionFailure("blob override grouping separator is empty")  // coverage:ignore
        }

        return NumberingSystemSymbols(decimalSeparator: decimal, groupingSeparator: grouping, minusSign: minus)
    }
}

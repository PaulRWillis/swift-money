import SwiftMoneyCore

/// The number-format section of the packed blob: one record per locale, holding the locale's separators,
/// grouping and the indices of its symbol and full-name patterns among the interned pattern arrays.
///
/// Byte layout, one fixed record per locale indexed directly by locale (no search); little-endian,
/// `StringRef` is offset then length:
/// - `decimalSeparator`, `groupingSeparator`, `minusSign`, `isoCodeSpacing`: four `StringRef`s.
/// - `primaryGroupingSize: UInt8`, `secondaryGroupingSize: UInt8`, `fullNameSpacing: UInt8`
///   (a ``Spacing/blobCode``).
/// - `patternIndex: UInt16`, `fullNamePatternIndex: UInt16` — into `patterns` / `fullNamePatterns`.
///
/// Stride 39. Patterns are interned (few distinct across all locales) and passed in as Swift arrays
/// rather than packed, so the blob holds only the per-locale index.
package struct NumberFormatTable {
    let reader: BlobReader
    let recordsOffset: Int
    let patterns: [MoneyFormatPattern]
    let fullNamePatterns: [FullNameLayout]

    static let recordStride = 39

    package init(
        reader: BlobReader,
        recordsOffset: Int,
        patterns: [MoneyFormatPattern],
        fullNamePatterns: [FullNameLayout]
    ) {
        self.reader = reader
        self.recordsOffset = recordsOffset
        self.patterns = patterns
        self.fullNamePatterns = fullNamePatterns
    }

    /// The number format for the locale at `localeIndex`.
    package func numberFormat(localeIndex: Int) -> LocaleNumberFormat {
        let record = recordsOffset + localeIndex * Self.recordStride

        let decimalSeparator = reader.string(reader.stringRef(at: record))
        let groupingRaw = reader.string(reader.stringRef(at: record + 8))
        let minusSign = reader.string(reader.stringRef(at: record + 16))
        let isoCodeSpacing = reader.string(reader.stringRef(at: record + 24))
        let primaryRaw = Int(reader.u8(at: record + 32))
        let secondaryRaw = Int(reader.u8(at: record + 33))
        let spacingCode = reader.u8(at: record + 34)
        let patternIndex = Int(reader.u16(at: record + 35))
        let fullNamePatternIndex = Int(reader.u16(at: record + 37))

        // The generator writes only valid values, so a failure here is a generator bug, not input.
        guard let groupingSeparator = GroupingSeparator(groupingRaw) else {
            preconditionFailure("blob grouping separator is empty")  // coverage:ignore
        }
        guard
            let primaryGroupingSize = GroupingSize(exactly: primaryRaw),
            let secondaryGroupingSize = GroupingSize(exactly: secondaryRaw)
        else {
            preconditionFailure("blob grouping size is not positive")  // coverage:ignore
        }
        guard let fullNameSpacing = Spacing(blobCode: spacingCode) else {
            preconditionFailure("blob full-name spacing code \(spacingCode) is unknown")  // coverage:ignore
        }

        return LocaleNumberFormat(
            decimalSeparator: decimalSeparator,
            groupingSeparator: groupingSeparator,
            minusSign: minusSign,
            primaryGroupingSize: primaryGroupingSize,
            secondaryGroupingSize: secondaryGroupingSize,
            pattern: patterns[patternIndex],
            fullNamePattern: fullNamePatterns[fullNamePatternIndex],
            isoCodeSpacing: isoCodeSpacing,
            fullNameSpacing: fullNameSpacing
        )
    }
}

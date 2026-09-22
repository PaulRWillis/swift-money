import SwiftMoneyCore

/// The number-format section of the packed blob: one record per locale, holding the locale's separators,
/// grouping and the indices of its symbol and full-name patterns among the interned pattern arrays.
///
/// Every integer is written as ``BlobDigits``, so a field's position is the width of the fields before
/// it. There is one fixed record per locale, indexed directly by ``LocaleIndex`` with no search.
/// Patterns are interned — few are distinct across all locales — so a record carries an index into the
/// arrays passed in here rather than a packed pattern of its own.
package struct NumberFormatTable: Sendable {
    let reader: BlobReader
    let recordsOffset: Int
    let patterns: [MoneyFormatPattern]
    let fullNamePatterns: [FullNameLayout]

    private enum Record {
        static let decimalSeparator = 0
        static let groupingSeparator = decimalSeparator + BlobDigits.stringRef
        static let minusSign = groupingSeparator + BlobDigits.stringRef
        static let isoCodeSpacing = minusSign + BlobDigits.stringRef
        static let primaryGroupingSize = isoCodeSpacing + BlobDigits.u8
        static let secondaryGroupingSize = primaryGroupingSize + BlobDigits.u8
        static let fullNameSpacing = secondaryGroupingSize + BlobDigits.u8
        static let patternIndex = fullNameSpacing + BlobDigits.u8
        static let fullNamePatternIndex = patternIndex + BlobDigits.u16
        static let stride = fullNamePatternIndex + BlobDigits.u16
    }

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
    package func numberFormat(localeIndex: LocaleIndex) -> LocaleNumberFormat {
        let record = recordsOffset + localeIndex.position * Record.stride

        let decimalSeparator = reader.string(reader.stringRef(at: record + Record.decimalSeparator))
        let groupingRaw = reader.string(reader.stringRef(at: record + Record.groupingSeparator))
        let minusSign = reader.string(reader.stringRef(at: record + Record.minusSign))
        let isoSpacingCode = reader.u8(at: record + Record.isoCodeSpacing)
        let primaryRaw = Int(reader.u8(at: record + Record.primaryGroupingSize))
        let secondaryRaw = Int(reader.u8(at: record + Record.secondaryGroupingSize))
        let spacingCode = reader.u8(at: record + Record.fullNameSpacing)
        let patternIndex = Int(reader.u16(at: record + Record.patternIndex))
        let fullNamePatternIndex = Int(reader.u16(at: record + Record.fullNamePatternIndex))

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
        guard let isoCodeSpacing = Spacing(blobCode: isoSpacingCode) else {
            preconditionFailure("blob iso-code spacing code \(isoSpacingCode) is unknown")  // coverage:ignore
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

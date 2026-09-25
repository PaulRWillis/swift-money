import SwiftMoneyCore

/// The packed CLDR tables: one static byte buffer holding a header, the locale keys, the three tables
/// and the string pool they point into, with the pattern arrays a number-format record indexes.
///
/// The buffer is self-describing: the header gives the locale count and where each section begins, so
/// the generator can lay the sections out as it likes and a reader needs nothing but the bytes. Every
/// field is written as ``BlobDigits``, and the header is:
/// - `localeCount: UInt32`;
/// - the offsets of the locale, number-format, currency-display, currency-full-name and plural-rule
///   sections, each a `UInt32`.
///
/// Patterns stay Swift values rather than packed bytes: only a handful are distinct across every locale,
/// so a record carries an index into these arrays.
package struct CLDRBlob: Sendable {
    /// Every covered locale's identifier, resolving one to the index the other sections are read with.
    package let locales: LocaleTable

    /// Each locale's separators, grouping and patterns.
    package let numberFormats: NumberFormatTable

    /// Each locale's currency symbols.
    package let currencyDisplays: CurrencyDisplayTable

    /// What each locale calls a currency in full.
    package let currencyFullNames: CurrencyFullNameTable

    /// Each language's plural rules, for choosing a full name's wording.
    package let pluralRules: PluralRuleTable

    /// Each supported numbering system's digits and, where it imposes them, its separators.
    package let numberingSystems: NumberingSystemTable

    /// The few per-locale separator overrides for a system that imposes its own.
    package let numberingSystemOverrides: NumberingSystemOverrideTable

    // The locale count is a count and stays a u32; the section positions are blob offsets.
    private enum Header {
        static let localeCount = 0
        static let locales = localeCount + BlobDigits.u32
        static let numberFormats = locales + BlobDigits.offset
        static let currencyDisplays = numberFormats + BlobDigits.offset
        static let currencyFullNames = currencyDisplays + BlobDigits.offset
        static let pluralRules = currencyFullNames + BlobDigits.offset
        static let numberingSystems = pluralRules + BlobDigits.offset
        static let numberingSystemOverrides = numberingSystems + BlobDigits.offset
        static let width = numberingSystemOverrides + BlobDigits.offset
    }

    /// How many bytes the header takes, which is where the generator lays out the first section.
    package static let headerWidth = Header.width

    /// Reads the tables the generator wrote into a string literal.
    ///
    /// - Parameters:
    ///   - bytes: The packed tables. A literal, so the bytes are static and outlive every read of them.
    ///   - patterns: The distinct symbol patterns, in the order a record's index counts.
    ///   - fullNamePatterns: The distinct full-name layouts, in the same way.
    package init(
        bytes: StaticString,
        patterns: [MoneyFormatPattern],
        fullNamePatterns: [FullNameLayout]
    ) {
        self.init(
            reader: BlobReader(base: bytes.utf8Start, count: bytes.utf8CodeUnitCount),
            patterns: patterns,
            fullNamePatterns: fullNamePatterns
        )
    }

    /// Reads the tables through a reader over their bytes, for a test that builds a blob of its own.
    package init(
        reader: BlobReader,
        patterns: [MoneyFormatPattern],
        fullNamePatterns: [FullNameLayout]
    ) {
        locales = LocaleTable(
            reader: reader,
            entriesOffset: reader.offsetField(at: Header.locales),
            localeCount: Int(reader.u32(at: Header.localeCount))
        )
        numberFormats = NumberFormatTable(
            reader: reader,
            recordsOffset: reader.offsetField(at: Header.numberFormats),
            patterns: patterns,
            fullNamePatterns: fullNamePatterns
        )
        currencyDisplays = CurrencyDisplayTable(
            reader: reader,
            directoryOffset: reader.offsetField(at: Header.currencyDisplays)
        )
        currencyFullNames = CurrencyFullNameTable(
            reader: reader,
            directoryOffset: reader.offsetField(at: Header.currencyFullNames)
        )
        pluralRules = PluralRuleTable(
            reader: reader,
            sectionOffset: reader.offsetField(at: Header.pluralRules)
        )
        numberingSystems = NumberingSystemTable(
            reader: reader,
            sectionOffset: reader.offsetField(at: Header.numberingSystems)
        )
        numberingSystemOverrides = NumberingSystemOverrideTable(
            reader: reader,
            sectionOffset: reader.offsetField(at: Header.numberingSystemOverrides)
        )
    }
}

import SwiftMoneyLocalization

// The finished tables, ready to write out: every locale's records and the pool they reference.
//
// The layout is the header, then the pool, then the four sections, and within a section the runs a
// directory points at come before the directory itself, so an offset is known by the time it has to be
// written. Each section's shape is documented on the type that reads it.
struct PackedTables {
    // In the order the tables index them: sorted by the key's UTF-8 bytes, which is the order
    // `LocaleTable` binary searches in.
    let locales: [PackedLocale]
    let pool: StringPool

    // One entry per language, sorted by the key's UTF-8 bytes. Keyed by language rather than locale,
    // since CLDR publishes plural rules per language.
    let pluralLanguages: [PackedPluralLanguage]

    func encoded() -> [UInt8] {
        var body = BlobWriter(base: CLDRBlob.headerWidth)
        body.append(pool.bytes)

        let localeKeys = writeLocaleKeys(into: &body)
        let numberFormats = writeNumberFormats(into: &body)
        let currencyFullNames = writeFullNames(into: &body)
        let currencyDisplays = writeDisplays(into: &body)
        let pluralRules = writePluralRules(into: &body)

        var header = BlobWriter(base: 0)
        header.u32(locales.count)
        header.u32(localeKeys)
        header.u32(numberFormats)
        header.u32(currencyDisplays)
        header.u32(currencyFullNames)
        header.u32(pluralRules)

        return header.bytes + body.bytes
    }

    private func writeLocaleKeys(into body: inout BlobWriter) -> Int {
        let offset = body.offset

        for locale in locales {
            body.ref(locale.key)
        }

        return offset
    }

    private func writeNumberFormats(into body: inout BlobWriter) -> Int {
        let offset = body.offset

        for locale in locales {
            let format = locale.numberFormat
            body.ref(format.decimalSeparator)
            body.ref(format.groupingSeparator)
            body.ref(format.minusSign)
            body.u8(format.isoCodeSpacing.blobCode)
            body.u8(format.primaryGroupingSize)
            body.u8(format.secondaryGroupingSize)
            body.u8(format.fullNameSpacing.blobCode)
            body.u16(format.patternIndex)
            body.u16(format.fullNamePatternIndex)
        }

        return offset
    }

    // The overrides first, then the records that point at them, then the directory that points at those.
    private func writeFullNames(into body: inout BlobWriter) -> Int {
        let overrides = locales.map { locale in
            locale.fullNames.map { name in writeOverrides(of: name, into: &body) }
        }

        let records = locales.enumerated().map { index, locale in
            let run = Run(start: body.offset, count: locale.fullNames.count)

            for (name, override) in zip(locale.fullNames, overrides[index]) {
                body.currencyCode(name.code.compactValue)
                body.ref(name.other)
                body.u32(override.start)
                body.u8(UInt8(override.count))
            }

            return run
        }

        return writeDirectory(records, into: &body)
    }

    private func writeOverrides(of name: PackedLocale.FullName, into body: inout BlobWriter) -> Run {
        let run = Run(start: body.offset, count: name.overrides.count)

        for override in name.overrides {
            body.u8(override.category.blobCode)
            body.ref(override.name)
        }

        return run
    }

    // A display record is self-contained, so identical display runs are byte-identical and share one run.
    private func writeDisplays(into body: inout BlobWriter) -> Int {
        var pool = RunPool()

        let records = locales.map { locale in
            let start = pool.offset(of: displayRunImage(of: locale), appendingTo: &body)
            return Run(start: start, count: locale.displays.count)
        }

        return writeDirectory(records, into: &body)
    }

    private func displayRunImage(of locale: PackedLocale) -> [UInt8] {
        var image = BlobWriter(base: 0)

        for display in locale.displays {
            image.currencyCode(display.code.compactValue)
            image.ref(display.standardSymbol)
            image.u8(display.standardSpacing.blobCode)
            image.ref(display.narrowSymbol)
            image.u8(display.narrowSpacing.blobCode)
        }

        return image.bytes
    }

    // Each language's rule entries first, then the directory (a language count and one entry per
    // language) that points back at them. An entry is a category byte then a flat, self-delimiting rule.
    private func writePluralRules(into body: inout BlobWriter) -> Int {
        let runs = pluralLanguages.map { language -> Run in
            let start = body.offset

            for (category, rule) in language.rules {
                body.u8(category.blobCode)
                writeRule(rule, into: &body)
            }

            return Run(start: start, count: language.rules.count)
        }

        let offset = body.offset
        body.u32(pluralLanguages.count)

        for (language, run) in zip(pluralLanguages, runs) {
            body.ref(language.key)
            body.u32(run.start)
            body.u8(UInt8(run.count))
        }

        return offset
    }

    private func writeRule(_ rule: PluralRule, into body: inout BlobWriter) {
        let groups = Array(rule.orOfAndGroups)
        body.u8(UInt8(groups.count))

        for group in groups {
            let relations = Array(group)
            body.u8(UInt8(relations.count))
            relations.forEach { writeRelation($0, into: &body) }
        }
    }

    private func writeRelation(_ relation: PluralRelation, into body: inout BlobWriter) {
        body.u8(relation.operand.blobCode)
        body.u32(relation.modulus.map(Int.init) ?? 0)   // 0 means no modulus, which is always ≥ 1

        let (sign, ranges) = signAndRanges(of: relation.comparison)
        body.u8(sign)

        let bounds = Array(ranges)
        body.u8(UInt8(bounds.count))

        for range in bounds {
            body.u32(codeValue(range.bounds.lowerBound))
            body.u32(codeValue(range.bounds.upperBound))
        }
    }

    private func signAndRanges(of comparison: PluralRelation.Comparison) -> (UInt8, NonEmpty<PluralRange>) {
        switch comparison {
        case .equals(let ranges): (0, ranges)
        case .notEquals(let ranges): (1, ranges)
        }
    }

    // A modulus (≤ 1,000,000) and a range bound both fit u32; a value that did not would truncate on the
    // wire, so refuse it here rather than ship a rule that reads back wrong.
    private func codeValue(_ value: UInt64) -> Int {
        precondition(value <= UInt64(UInt32.max), "plural value \(value) does not fit a u32 field")
        return Int(value)
    }

    private func writeDirectory(_ records: [Run], into body: inout BlobWriter) -> Int {
        let offset = body.offset

        for run in records {
            body.u32(run.start)
            body.u16(UInt16(run.count))
        }

        return offset
    }

    // Where a run of records begins and how many there are: what a directory entry holds.
    private struct Run {
        let start: Int
        let count: Int
    }
}

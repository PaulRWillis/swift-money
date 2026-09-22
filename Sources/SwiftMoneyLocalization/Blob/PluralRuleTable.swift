/// The plural-rule section of the packed blob: per language, the rule that picks each plural category,
/// used to choose a currency's full-name wording for an amount.
///
/// Every integer is written as ``BlobDigits``. The section is a **directory** of one entry per language,
/// each pointing at that language's rule entries; an entry is a category byte followed by a flat,
/// self-delimiting rule. The rules are keyed by language, not by ``LocaleIndex``, so the whole section is
/// decoded once into the dictionary ``MoneyLocalization`` looks a language up in.
package struct PluralRuleTable: Sendable {
    let reader: BlobReader
    let sectionOffset: Int

    private enum Section {
        static let languageCount = 0
        static let entries = languageCount + BlobDigits.u32
    }

    private enum Entry {
        static let languageKey = 0
        static let rulesStart = languageKey + BlobDigits.stringRef
        static let ruleCount = rulesStart + BlobDigits.u32
        static let stride = ruleCount + BlobDigits.u8
    }

    package init(reader: BlobReader, sectionOffset: Int) {
        self.reader = reader
        self.sectionOffset = sectionOffset
    }

    /// Every language's rules, keyed by language then by category, decoded in one pass.
    package func allRules() -> [String: [PluralCategory: PluralRule]] {
        let languageCount = Int(reader.u32(at: sectionOffset + Section.languageCount))
        let entriesOffset = sectionOffset + Section.entries

        var result: [String: [PluralCategory: PluralRule]] = [:]
        result.reserveCapacity(languageCount)

        for index in 0 ..< languageCount {
            let entry = entriesOffset + index * Entry.stride
            let language = reader.string(reader.stringRef(at: entry + Entry.languageKey))
            let rulesStart = Int(reader.u32(at: entry + Entry.rulesStart))
            let ruleCount = Int(reader.u8(at: entry + Entry.ruleCount))
            result[language] = rules(at: rulesStart, count: ruleCount)
        }

        return result
    }

    private func rules(at start: Int, count: Int) -> [PluralCategory: PluralRule] {
        var cursor = start
        var byCategory: [PluralCategory: PluralRule] = [:]

        for _ in 0 ..< count {
            let category = readCategory(&cursor)
            byCategory[category] = readRule(&cursor)
        }

        return byCategory
    }

    private func readRule(_ cursor: inout Int) -> PluralRule {
        let groups = (0 ..< Int(readU8(&cursor))).map { _ in readGroup(&cursor) }
        return PluralRule(orOfAndGroups: nonEmpty(groups))
    }

    private func readGroup(_ cursor: inout Int) -> NonEmpty<PluralRelation> {
        let relations = (0 ..< Int(readU8(&cursor))).map { _ in readRelation(&cursor) }
        return nonEmpty(relations)
    }

    private func readRelation(_ cursor: inout Int) -> PluralRelation {
        let operand = readOperand(&cursor)
        let modulus = readModulus(&cursor)
        let equals = readU8(&cursor) == 0
        let ranges = nonEmpty((0 ..< Int(readU8(&cursor))).map { _ in readRange(&cursor) })
        return PluralRelation(
            operand: operand,
            modulus: modulus,
            comparison: equals ? .equals(ranges) : .notEquals(ranges)
        )
    }

    private func readModulus(_ cursor: inout Int) -> PluralModulus? {
        let raw = Int(readU32(&cursor))
        guard raw != 0 else {
            return nil
        }
        // The generator writes only a positive modulus, so a failure here is a generator bug, not input.
        guard let modulus = PluralModulus(exactly: raw) else {
            preconditionFailure("blob plural modulus \(raw) is not positive")  // coverage:ignore
        }
        return modulus
    }

    private func readRange(_ cursor: inout Int) -> PluralRange {
        let low = UInt64(readU32(&cursor))
        let high = UInt64(readU32(&cursor))
        return PluralRange(low ... high)
    }

    private func readOperand(_ cursor: inout Int) -> PluralOperand {
        let code = readU8(&cursor)
        // The generator writes only valid codes, so a failure here is a generator bug, not input.
        guard let operand = PluralOperand(blobCode: code) else {
            preconditionFailure("blob plural operand code \(code) is unknown")  // coverage:ignore
        }
        return operand
    }

    private func readCategory(_ cursor: inout Int) -> PluralCategory {
        let code = readU8(&cursor)
        // The generator writes only valid codes, so a failure here is a generator bug, not input.
        guard let category = PluralCategory(blobCode: code) else {
            preconditionFailure("blob plural category code \(code) is unknown")  // coverage:ignore
        }
        return category
    }

    private func readU8(_ cursor: inout Int) -> UInt8 {
        defer { cursor += BlobDigits.u8 }
        return reader.u8(at: cursor)
    }

    private func readU32(_ cursor: inout Int) -> UInt32 {
        defer { cursor += BlobDigits.u32 }
        return reader.u32(at: cursor)
    }

    // A rule always has at least one group, a group at least one relation, and a comparison at least one
    // range, so the generator never writes an empty run and a nil here is a generator bug.
    private func nonEmpty<Element>(_ elements: [Element]) -> NonEmpty<Element> {
        guard let nonEmpty = NonEmpty(elements) else {
            preconditionFailure("blob plural rule has an empty run")  // coverage:ignore
        }
        return nonEmpty
    }
}

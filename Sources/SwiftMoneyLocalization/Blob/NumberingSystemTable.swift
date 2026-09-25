import SwiftMoneyCore

/// The numbering-system section of the packed blob: one record per supported system, holding its digit
/// glyphs and, for a system that imposes its own separators, those separators.
///
/// Every integer is written as ``BlobDigits``, so a field's position is the width of the fields before it.
/// The section is a count followed by fixed records **sorted by system name**, so a name resolves to a
/// ``SystemIndex`` by binary search. A record's separators are meaningful only when its provenance tag is
/// `imposesOwn`; a `reusesLocale` record leaves them empty and decodes to ``SeparatorProvenance/reusesLocale``.
package struct NumberingSystemTable: Sendable {
    let reader: BlobReader
    let recordsOffset: Int

    /// How many systems the section holds.
    package let count: Int

    private enum Section {
        static let count = 0
        static let records = count + BlobDigits.u16
    }

    private enum Record {
        static let name = 0
        static let provenanceTag = name + BlobDigits.stringRef
        static let digits = provenanceTag + BlobDigits.u8
        static let decimalSeparator = digits + BlobDigits.stringRef
        static let groupingSeparator = decimalSeparator + BlobDigits.stringRef
        static let minusSign = groupingSeparator + BlobDigits.stringRef
        static let stride = minusSign + BlobDigits.stringRef
    }

    // The wire values of a record's provenance tag. `reusesLocale` is zero so a default-initialized field
    // reads as the common shape.
    package enum ProvenanceTag {
        package static let reusesLocale: UInt8 = 0
        package static let imposesOwn: UInt8 = 1
    }

    package init(reader: BlobReader, sectionOffset: Int) {
        self.reader = reader
        self.count = Int(reader.u16(at: sectionOffset + Section.count))
        self.recordsOffset = sectionOffset + Section.records
    }

    /// The index of the system named `identifier`, or `nil` when no supported system has that name.
    package func index(of identifier: String) -> SystemIndex? {
        let query = Array(identifier.utf8)
        var low = 0
        var high = count

        while low < high {
            let middle = (low + high) / 2
            switch order(ofNameAt: middle, against: query) {
            case .equal: return SystemIndex(position: middle)
            case .before: low = middle + 1
            case .after: high = middle
            }
        }

        return nil
    }

    /// The digit glyphs the system at `index` writes with: ASCII for `latn`, its own ten otherwise.
    package func digits(at index: SystemIndex) -> Digits {
        let glyphs = reader.string(reader.stringRef(at: record(index) + Record.digits))

        // An empty glyph string marks the ASCII digits; the rest carry their own ten, decoded the same
        // way ``NumberFormatTable`` decodes a locale's.
        if glyphs.isEmpty {
            return .ascii
        } else if let set = DigitGlyphs(glyphs) {
            return .glyphs(set)
        } else {
            preconditionFailure("blob numbering-system digits are not ten uniform-width glyphs")  // coverage:ignore
        }
    }

    /// Where the system at `index` takes its separators from: its own, or the locale's.
    package func provenance(at index: SystemIndex) -> SeparatorProvenance {
        let base = record(index)
        let tag = reader.u8(at: base + Record.provenanceTag)

        switch tag {
        case ProvenanceTag.reusesLocale:
            return .reusesLocale
        case ProvenanceTag.imposesOwn:
            let decimal = reader.string(reader.stringRef(at: base + Record.decimalSeparator))
            let groupingRaw = reader.string(reader.stringRef(at: base + Record.groupingSeparator))
            let minus = reader.string(reader.stringRef(at: base + Record.minusSign))

            // The generator writes a non-empty grouping separator for every imposing system.
            guard let grouping = GroupingSeparator(groupingRaw) else {
                preconditionFailure("blob numbering-system grouping separator is empty")  // coverage:ignore
            }

            return .imposesOwn(NumberingSystemSymbols(
                decimalSeparator: decimal, groupingSeparator: grouping, minusSign: minus
            ))
        default:
            preconditionFailure("blob numbering-system provenance tag \(tag) is unknown")  // coverage:ignore
        }
    }

    /// The name of the system at `index`, for tests and diagnostics.
    package func name(at index: SystemIndex) -> String {
        reader.string(reader.stringRef(at: record(index) + Record.name))
    }

    private func record(_ index: SystemIndex) -> Int {
        recordsOffset + index.position * Record.stride
    }

    // Where the stored name at `entry` sorts against the query bytes, compared out of the pool so neither
    // side is copied into a string. Names are ASCII, so byte order is name order.
    private func order(ofNameAt entry: Int, against query: [UInt8]) -> Order {
        let stored = reader.stringRef(at: recordsOffset + entry * Record.stride + Record.name)
        var position = 0

        for wanted in query {
            guard position < Int(stored.length) else {
                return .before  // the stored name is a prefix of the one wanted
            }

            let byte = reader.byte(at: Int(stored.offset) + position)
            guard byte == wanted else {
                return byte < wanted ? .before : .after
            }

            position += 1
        }

        return position == Int(stored.length) ? .equal : .after
    }

    private enum Order {
        case before
        case equal
        case after
    }
}

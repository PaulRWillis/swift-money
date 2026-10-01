import SwiftMoneyCore

/// The currency-display section of the packed blob: per locale, the currencies whose symbol differs from
/// their code, each with a standard and narrow symbol, their spacings, and whether a letter touches the
/// number in each.
///
/// Every integer is written as ``BlobDigits``, so a field's position is the width of the fields before
/// it. The section is a **directory** of one entry per locale, indexed by ``LocaleIndex``, and the
/// **records** it points at, sorted by ``Localization/CurrencyCode`` so a currency is found by binary
/// search.
package struct CurrencyDisplayTable: Sendable {
    let reader: BlobReader
    let directoryOffset: Int

    private enum Entry {
        static let recordsStart = 0
        static let recordCount = recordsStart + BlobDigits.offset
        static let stride = recordCount + BlobDigits.u16
    }

    private enum Record {
        static let code = 0
        static let standardSymbol = code + Localization.CurrencyCode.digitCount
        static let standardSpacing = standardSymbol + BlobDigits.stringRef
        static let narrowSymbol = standardSpacing + BlobDigits.u8
        static let narrowSpacing = narrowSymbol + BlobDigits.stringRef
        // Bit 0 is `standardForm`, bit 1 is `narrowForm`, each a `SymbolForm.blobBit`.
        static let forms = narrowSpacing + BlobDigits.u8
        static let stride = forms + BlobDigits.u8
    }

    // The forms bit field's two positions within the byte.
    private enum FormsBit {
        static let standard: UInt8 = 0
        static let narrow: UInt8 = 1
    }

    package init(reader: BlobReader, directoryOffset: Int) {
        self.reader = reader
        self.directoryOffset = directoryOffset
    }

    /// How `code` is displayed in the locale at `localeIndex`, or `nil` if it has no distinct symbol
    /// there (the caller then falls back to the code).
    package func display(localeIndex: LocaleIndex, code: CurrencyCode) -> CurrencyDisplay? {
        guard let tableCode = Localization.CurrencyCode(code) else {
            return nil
        }

        let entry = directoryOffset + localeIndex.position * Entry.stride
        let recordsStart = reader.offsetField(at: entry + Entry.recordsStart)
        let recordCount = Int(reader.u16(at: entry + Entry.recordCount))

        guard let record = reader.recordOffset(
            of: tableCode, start: recordsStart, count: recordCount, stride: Record.stride
        ) else {
            return nil
        }

        let formsByte = reader.u8(at: record + Record.forms)

        return CurrencyDisplay(
            standardSymbol: reader.string(reader.stringRef(at: record + Record.standardSymbol)),
            standardSpacing: spacing(at: record + Record.standardSpacing),
            standardForm: form(formsByte, bit: FormsBit.standard),
            narrowSymbol: reader.string(reader.stringRef(at: record + Record.narrowSymbol)),
            narrowSpacing: spacing(at: record + Record.narrowSpacing),
            narrowForm: form(formsByte, bit: FormsBit.narrow)
        )
    }

    // The generator writes only valid codes, so an unknown one is a generator bug, not input.
    private func spacing(at offset: Int) -> Spacing {
        let code = reader.u8(at: offset)
        guard let spacing = Spacing(blobCode: code) else {
            preconditionFailure("blob currency spacing code \(code) is unknown")  // coverage:ignore
        }
        return spacing
    }

    // The form at one bit position of the packed byte. The generator writes only valid bits, so an
    // unknown one is a generator bug, not input.
    private func form(_ byte: UInt8, bit: UInt8) -> SymbolForm {
        let value = (byte >> bit) & 1
        guard let form = SymbolForm(blobBit: value) else {
            preconditionFailure("blob symbol form bit \(value) is unknown")  // coverage:ignore
        }
        return form
    }
}

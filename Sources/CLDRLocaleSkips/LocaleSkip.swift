import CLDRCurrencyPatterns
import SwiftMoneyLocalization

/// Why the generator cannot build tables for a CLDR locale.
///
/// Each case names something the locale publishes that the packed tables have no shape for. A locale
/// that raises one is left out and keeps the runtime's ICU fallback, so the covered set widens on its
/// own as later work adds the missing shapes, with no hand-kept list of locales to maintain.
///
/// A fault in how the generator *reads* CLDR is not one of these. That stops the run, because it would
/// otherwise be recorded as a property of the locale rather than of the generator.
package enum LocaleSkip: Error, Equatable, Sendable {
    /// The locale writes amounts in digits other than `0` to `9`.
    case nonLatinDigits(numberingSystem: String)

    /// The locale's standard pattern arranges a negative amount itself, instead of leaving the leading
    /// sign the tables assume.
    case negativeSubpattern(pattern: String)

    /// CLDR publishes no plural rules for the locale's language, so a currency name cannot be chosen
    /// by amount.
    case noPluralRules(language: String)

    /// The language's plural rules use a relation the rule engine does not model, such as `within`.
    ///
    /// Distinct from a rule this tool simply misreads, which stops the run: this one CLDR's grammar
    /// allows and the engine has no shape for, so the locale waits for one.
    case unsupportedPluralRule(language: String, relation: String)

    /// A currency written with letters rearranges the pattern, which one pattern per locale cannot say.
    case unrepresentablePattern(UnsupportedPattern, field: PatternField)

    /// The pattern has no currency placeholder, or no digits to place one against.
    case noCurrencyPlaceholder(pattern: String)

    /// The locale spaces a currency differently before and after the digits.
    case asymmetricCurrencySpacing(before: String, after: String)

    /// The locale decides currency spacing by a rule the generator does not evaluate.
    case unreadableCurrencySpacing(rule: String)

    /// The gap between a currency and the digits is not one a packed spacing code can hold.
    case unrepresentableGap(String, symbol: String)

    /// The locale's currency names do not share a single gap, which one packed spacing cannot hold.
    case multipleNameGaps(Set<Spacing>)
}

package extension LocaleSkip {
    /// The category this skip falls under, carrying nothing specific to the locale that raised it.
    ///
    /// The report groups and counts on this, so two locales skipped for one cause have to produce the
    /// same string. Anything that varies between them belongs in ``detail``.
    var reason: String {
        switch self {
        case .nonLatinDigits:
            "writes amounts in digits other than 0 to 9"
        case .negativeSubpattern:
            "arranges a negative amount in its standard pattern"
        case .noPluralRules:
            "has no published plural rules for its language"
        case .unsupportedPluralRule:
            "states a plural rule with a relation this tool does not model"
        case .unrepresentablePattern(let pattern, let field):
            "\(Self.rearrangement(pattern)), in its \(field.rawValue) pattern"
        case .noCurrencyPlaceholder:
            "writes a currency pattern with no currency or no digits"
        case .asymmetricCurrencySpacing:
            "spaces a currency differently before and after the digits"
        case .unreadableCurrencySpacing:
            "decides currency spacing by a rule this tool does not evaluate"
        case .unrepresentableGap:
            "writes a gap between currency and digits that no spacing code holds"
        case .multipleNameGaps:
            "writes its currency names with more than one gap"
        }
    }

    /// What this locale in particular published, ready to read in a report.
    ///
    /// Empty when the reason already says everything. Characters outside printable ASCII are escaped,
    /// because most of what appears here is spacing and two widths of space look alike on a page.
    var detail: String {
        switch self {
        case .nonLatinDigits(let numberingSystem):
            numberingSystem
        case .negativeSubpattern(let pattern), .noCurrencyPlaceholder(let pattern):
            Self.readable(pattern)
        case .noPluralRules(let language):
            language
        case .unsupportedPluralRule(let language, let relation):
            "\(language) uses \(Self.readable(relation))"
        case .unrepresentablePattern(.unmodelled(let pattern, let letterSymbolPattern), _):
            "\(Self.readable(pattern)) against \(Self.readable(letterSymbolPattern))"
        case .unrepresentablePattern:
            ""
        case .asymmetricCurrencySpacing(let before, let after):
            "\(Self.readable(before)) against \(Self.readable(after))"
        case .unreadableCurrencySpacing(let rule):
            Self.readable(rule)
        case .unrepresentableGap(let gap, let symbol):
            "\(Self.escapingEveryScalar(gap)) beside \(Self.readable(symbol))"
        case .multipleNameGaps(let spacings):
            spacings.map(Self.readable).sorted().joined(separator: ", ")
        }
    }

    // The three shapes `UnsupportedPattern` distinguishes, said as a category rather than as the two
    // patterns it holds: those go in the detail, so that locales sharing a cause group together.
    private static func rearrangement(_ pattern: UnsupportedPattern) -> String {
        switch pattern {
        case .currencyMovesForLetterSymbols:
            "moves the currency to the other side of the digits for a currency written with letters"
        case .groupingChangesForLetterSymbols:
            "groups the digits differently for a currency written with letters"
        case .unmodelled:
            "arranges a currency written with letters in a way this tool does not model"
        }
    }

    // A gap is whitespace throughout, and a plain space is as invisible in a report as a no-break one,
    // so every scalar is escaped here rather than only the ones outside printable ASCII. An empty gap
    // has nothing to escape and is named instead.
    private static func readable(_ spacing: Spacing) -> String {
        spacing.rendered.isEmpty ? "(none)" : escapingEveryScalar(spacing.rendered)
    }

    private static func escapingEveryScalar(_ text: String) -> String {
        text.unicodeScalars.map(escaped).joined()
    }

    private static func readable(_ text: String) -> String {
        text.unicodeScalars
            .map { (0x20 ... 0x7E).contains($0.value) ? String($0) : escaped($0) }
            .joined()
    }

    private static func escaped(_ scalar: Unicode.Scalar) -> String {
        "\\u{\(String(scalar.value, radix: 16, uppercase: true))}"
    }
}

extension LocaleSkip: CustomStringConvertible {
    package var description: String {
        detail.isEmpty ? reason : "\(reason): \(detail)"
    }
}

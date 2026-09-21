// A dev-only tool. Reads the pinned CLDR JSON (fetched via npm into Tools/cldr/node_modules) and emits
// the Swift data tables that SwiftMoneyLocalization composes into a MoneyFormat. Not part of any library
// product; run with `swift run GenerateSwiftMoneyLocalization` after `npm ci` in Tools/cldr.
//
// This tool builds against the module it writes into, so a generated file that does not compile stops
// the tool that would replace it. Patch the generated file by hand, or restore it with `git checkout`,
// far enough to compile, then rerun: the next run overwrites it anyway.
//
// CLDR encodes currency spacing two ways: a literal space inside the format pattern (e.g. the NBSP in
// "#,##0.00 ¤"), and a currencySpacing rule that inserts a space between the number and a symbol whose
// touching character is neither a Unicode Symbol nor a separator (so ISO codes like "GBP" get a space,
// but "£"/"€" do not). This tool resolves that rule at generation time — using the full Swift Unicode
// tables, which Embedded lacks — and bakes the resulting spacing string into the data, so the runtime
// target needs no Unicode-category lookups.

import CLDRPluralParsing
import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

let cldrVersion = "48.0.0"
let locales = ["en", "en-GB", "de", "fr", "ja"]

// Plural rules are published per language, so a region keeps its language's rules.
let languages = locales.map { String($0.prefix { $0 != "-" }) }.uniqued()

let repoRoot = FileManager.default.currentDirectoryPath
let cldrMain = "\(repoRoot)/Tools/cldr/node_modules/cldr-numbers-full/main"
let cldrSupplemental = "\(repoRoot)/Tools/cldr/node_modules/cldr-core/supplemental"
let outputPath = "\(repoRoot)/Sources/SwiftMoneyLocalization/Generated/CLDRTables.swift"

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}

// MARK: - CLDR reading

func json(_ path: String) -> [String: Any] {
    guard let data = FileManager.default.contents(atPath: path),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        fatalError("Could not read CLDR JSON at \(path)")
    }
    return object
}

func numbers(_ locale: String) -> [String: Any] {
    let root = json("\(cldrMain)/\(locale)/numbers.json")
    let main = root["main"] as! [String: Any]
    let entry = main[locale] as! [String: Any]
    return entry["numbers"] as! [String: Any]
}

func currencies(_ locale: String) -> [String: [String: String]] {
    let root = json("\(cldrMain)/\(locale)/currencies.json")
    let main = root["main"] as! [String: Any]
    let entry = main[locale] as! [String: Any]
    let numbers = entry["numbers"] as! [String: Any]
    let currencies = numbers["currencies"] as! [String: Any]
    return currencies.mapValues { $0 as! [String: String] }
}

// MARK: - Pattern parsing

enum Placement: String { case before = ".before", after = ".after" }

let numberChars: Set<Character> = ["#", "0", ".", ",", "\u{00A0}\u{00A0}".first!]  // #,0,. and , only
let integerNumberChars: Set<Character> = ["#", "0", ",", "."]

struct ParsedPattern {
    let placement: Placement
    let patternSpacing: String
    let primaryGroupingSize: Int
    let secondaryGroupingSize: Int
    let accountingNegative: String
}

func parse(standard: String, accounting: String) -> ParsedPattern {
    let positive = String(standard.split(separator: ";").first ?? Substring(standard))

    let symbolIndex = positive.firstIndex(of: "¤")!
    let firstNumber = positive.firstIndex { integerNumberChars.contains($0) }!

    let placement: Placement = symbolIndex < firstNumber ? .before : .after
    let patternSpacing: String
    if placement == .before {
        // Chars between ¤ and the first number character.
        patternSpacing = String(positive[positive.index(after: symbolIndex) ..< firstNumber])
    } else {
        // Chars between the last number character and ¤.
        let lastNumber = positive.lastIndex { integerNumberChars.contains($0) }!
        patternSpacing = String(positive[positive.index(after: lastNumber) ..< symbolIndex])
    }

    // Grouping: the integer subpattern (before the decimal point), split on the group separator.
    let integerPart = positive.prefix { $0 != "." }.filter { $0 == "#" || $0 == "0" || $0 == "," }
    let groups = integerPart.split(separator: ",", omittingEmptySubsequences: false).map(\.count)
    let primary = groups.last ?? 3
    let secondary = groups.count >= 3 ? groups[groups.count - 2] : primary

    // Accounting wraps negatives in parentheses when its negative subpattern does, else it uses a minus.
    let negativeSubpattern = accounting.split(separator: ";").dropFirst().first ?? ""
    let accountingNegative = negativeSubpattern.contains("(") ? ".parentheses" : ".minusSign"

    return ParsedPattern(
        placement: placement,
        patternSpacing: patternSpacing,
        primaryGroupingSize: primary,
        secondaryGroupingSize: secondary,
        accountingNegative: accountingNegative
    )
}

// MARK: - Patterns as affixes

func affixesLiteral(prefix: [String], suffix: [String]) -> String {
    "MoneyFormatAffixes(prefix: [\(prefix.joined(separator: ", "))], suffix: [\(suffix.joined(separator: ", "))])"
}

// One arrangement of a currency beside the digits, as the tokens before and after the implicit number
// body. The spacing is a token rather than text, because what fills it depends on the currency: CLDR's
// currencySpacing rule resolves per symbol.
func currencyAffix(placement: Placement) -> (prefix: [String], suffix: [String]) {
    placement == .before
        ? (prefix: [".currency", ".currencySpacing"], suffix: [])
        : (prefix: [], suffix: [".currencySpacing", ".currency"])
}

// A locale's three arrangements. None of the locales here gives its standard pattern a negative
// subpattern, so a negative is the positive arrangement with a sign in front, which is CLDR's own
// default; the accounting form either wraps that in parentheses or falls back to the same minus.
func patternLiteral(placement: Placement, accountingNegative: String) -> String {
    let body = currencyAffix(placement: placement)
    // The sign slot leads the arrangement: CLDR writes a negative's minus at the very front for every
    // locale here, and a plus, where the options ask for one, goes wherever the minus would have gone.
    let signed = affixesLiteral(prefix: [".sign"] + body.prefix, suffix: body.suffix)
    let accounting = accountingNegative == ".parentheses"
        ? affixesLiteral(prefix: [".literal(\"(\")"] + body.prefix, suffix: body.suffix + [".literal(\")\")"])
        : signed

    return """
        MoneyFormatPattern(
                    positive: \(signed),
                    negative: \(signed),
                    accountingNegative: \(accounting)
                )
        """
}

// MARK: - Currency spacing (resolved here, baked into the data)

func isSymbolOrSeparator(_ character: Character) -> Bool {
    guard let scalar = character.unicodeScalars.first else { return false }
    switch scalar.properties.generalCategory {
    case .currencySymbol, .modifierSymbol, .mathSymbol, .otherSymbol,
         .spaceSeparator, .lineSeparator, .paragraphSeparator:
        return true
    default:
        return false
    }
}

// The space between symbol and digits for a resolved symbol string: the pattern's literal spacing if it
// has any, else the currencySpacing insertion when the touching character is not a symbol/separator.
func spacing(for symbol: String, placement: Placement, patternSpacing: String, insertBetween: String) -> String {
    if !patternSpacing.isEmpty {
        return patternSpacing
    }
    let boundary = placement == .before ? symbol.last : symbol.first
    guard let boundary, !isSymbolOrSeparator(boundary) else {
        return ""
    }
    return insertBetween
}

// MARK: - Full names

// One CLDR unit pattern, such as "{0} {1}", "{1}{0}" or "{0} de {1}", turned into the tokens a
// full-name layout writes before and after the digits. `{0}` is the number body and `{1}` the
// currency; a run of a recognised gap becomes `.currencySpacing`, any other text (Romanian's " de ")
// a `.literal`. The number is formatted with its own sign, so `.sign` sits next to the body — the end
// of the prefix — rather than outermost as in a symbol pattern.
struct ExpandedUnitPattern {
    let prefix: [String]
    let suffix: [String]
    let spacing: Spacing?
}

func expandUnitPattern(_ pattern: String, locale: String) -> ExpandedUnitPattern {
    guard let zero = pattern.range(of: "{0}") else {
        fatalError("\(locale) unit pattern \(quote(pattern)) has no {0}")
    }

    var spacing: Spacing?
    func tokens(_ text: Substring) -> [String] {
        var result: [String] = []
        for (index, segment) in String(text).components(separatedBy: "{1}").enumerated() {
            if index > 0 {
                result.append(".currency")
            }
            guard !segment.isEmpty else { continue }
            if let gap = Spacing(rendering: segment) {
                spacing = gap
                result.append(".currencySpacing")
            } else {
                result.append(".literal(\(quote(segment)))")
            }
        }
        return result
    }

    let before = tokens(pattern[..<zero.lowerBound])
    let after = tokens(pattern[zero.upperBound...])
    return ExpandedUnitPattern(prefix: before + [".sign"], suffix: after, spacing: spacing)
}

// A locale's full-name layout: the `other` arrangement CLDR always publishes, any category that
// arranges the name differently, and the one recognised gap the categories share. CLDR may join the
// name per plural category (Romanian's `other` writes "de"), so this reads every category, not one.
func fullNameLayout(_ patterns: [String: String], locale: String) -> (literal: String, spacing: Spacing) {
    guard let otherPattern = patterns["unitPattern-count-other"] else {
        fatalError("\(locale) has no unitPattern-count-other")
    }

    var spacings: Set<Spacing> = []
    func expand(_ pattern: String) -> ExpandedUnitPattern {
        let expanded = expandUnitPattern(pattern, locale: locale)
        expanded.spacing.map { spacings.insert($0) }
        return expanded
    }

    let other = expand(otherPattern)
    let overrides = PluralCategory.allCases.compactMap { category -> String? in
        guard category != .other, let pattern = patterns["unitPattern-count-\(category.rawValue)"] else {
            return nil
        }
        let expanded = expand(pattern)
        guard expanded.prefix != other.prefix || expanded.suffix != other.suffix else {
            return nil
        }
        return ".\(category.rawValue): \(affixesLiteral(prefix: expanded.prefix, suffix: expanded.suffix))"
    }

    guard spacings.count <= 1 else {
        fatalError("\(locale) writes a currency name with more than one gap: \(spacings)")
    }

    let byCategory = overrides.isEmpty ? "" : ", byCategory: [\(overrides.joined(separator: ", "))]"
    let literal = "FullNameLayout(other: \(affixesLiteral(prefix: other.prefix, suffix: other.suffix))\(byCategory))"
    return (literal, spacings.first ?? .none)
}

// What a locale calls one currency: the name CLDR always publishes, and any form that differs from
// it. A form equal to `other` is left out, since it resolves to `other` anyway.
struct FullName {
    let code: String
    let other: String
    let byCategory: [PluralCategory: String]
}

// What a locale calls each currency the library ships. A currency CLDR does not name there is left
// out, and the runtime falls back for it.
func fullNames(_ currencies: [String: [String: String]]) -> [FullName] {
    Currency.allISO4217.compactMap { currency in
        let code = String(currency.code)
        guard let fields = currencies[code], let other = fields["displayName-count-other"] else {
            return nil
        }

        let byCategory = PluralCategory.allCases.reduce(into: [PluralCategory: String]()) { names, category in
            guard category != .other, let name = fields["displayName-count-\(category.rawValue)"], name != other else {
                return
            }
            names[category] = name
        }

        return FullName(code: code, other: other, byCategory: byCategory)
    }
}

// MARK: - Plural rules

// Every locale's rule text, keyed by language then by CLDR's `pluralRule-count-<category>`.
func cardinalRuleText() -> [String: [String: String]] {
    let root = json("\(cldrSupplemental)/plurals.json")
    guard let supplemental = root["supplemental"] as? [String: Any],
          let cardinal = supplemental["plurals-type-cardinal"] as? [String: [String: String]] else {
        fatalError("Could not read the cardinal plural rules from plurals.json")
    }
    return cardinal
}

// One language's rules, read from CLDR's text. `other` carries no condition, so it has no rule: the
// runtime falls back to it when no other rule holds.
func pluralRules(for language: String, in text: [String: [String: String]]) -> [(PluralCategory, PluralRule)] {
    guard let published = text[language] else {
        fatalError("CLDR publishes no plural rules for \(language)")
    }

    return PluralCategory.allCases.compactMap { category in
        guard let line = published["pluralRule-count-\(category.rawValue)"] else {
            return nil
        }

        guard let parsed = try? PluralRuleText(parsing: line) else {
            fatalError("Could not read \(language)'s rule for \(category.rawValue): \(line)")
        }

        return parsed.rule.map { (category, $0) }
    }
}

// CLDR publishes, beside each rule, the values that rule is meant to cover. Running them back
// through the rules checks the reading of every locale CLDR knows, not just the few the library
// ships, so a rule this tool would misread surfaces now rather than when that locale is added.
func checkEveryLocaleAgainstItsSamples(_ text: [String: [String: String]]) {
    var checked = 0

    for (language, published) in text.sorted(by: { $0.key < $1.key }) {
        var rules: [PluralCategory: PluralRule] = [:]
        var samples: [(category: PluralCategory, sample: PluralSample)] = []

        for category in PluralCategory.allCases {
            guard let line = published["pluralRule-count-\(category.rawValue)"] else {
                continue
            }

            guard let parsed = try? PluralRuleText(parsing: line) else {
                fatalError("Could not read \(language)'s rule for \(category.rawValue): \(line)")
            }

            parsed.rule.map { rules[category] = $0 }
            samples += parsed.samples.map { (category, $0) }
        }

        for (category, sample) in samples {
            let operands = PluralOperandValues(minorUnits: sample.minorUnits, unitScale: sample.unitScale)
            let resolved = PluralCategory.allCases.first { rules[$0]?.matches(operands) == true } ?? .other

            guard resolved == category else {
                fatalError("\(language) \(sample) resolves to \(resolved.rawValue), CLDR publishes it under \(category.rawValue)")
            }
        }

        checked += samples.count
    }

    print("Checked \(checked) CLDR samples across \(text.count) locales.")
}

// MARK: - Swift emission

func nonEmptyLiteral(_ elements: [String]) -> String {
    guard let first = elements.first else {
        fatalError("A NonEmpty cannot be written from nothing")
    }

    let rest = elements.dropFirst()
    return rest.isEmpty ? "NonEmpty(\(first))" : "NonEmpty(\(first), [\(rest.joined(separator: ", "))])"
}

func literal(_ operand: PluralOperand) -> String {
    switch operand {
    case .absoluteValue: ".absoluteValue"
    case .integerPart: ".integerPart"
    case .fractionDigitCount: ".fractionDigitCount"
    case .significantFractionDigitCount: ".significantFractionDigitCount"
    case .fractionDigits: ".fractionDigits"
    case .significantFractionDigits: ".significantFractionDigits"
    case .compactExponent: ".compactExponent"
    }
}

func literal(_ range: PluralRange) -> String {
    let bounds = range.bounds
    return bounds.lowerBound == bounds.upperBound
        ? "PluralRange(\(bounds.lowerBound))"
        : "PluralRange(\(bounds.lowerBound) ... \(bounds.upperBound))"
}

func literal(_ comparison: PluralRelation.Comparison) -> String {
    switch comparison {
    case .equals(let ranges): ".equals(\(nonEmptyLiteral(ranges.map(literal))))"
    case .notEquals(let ranges): ".notEquals(\(nonEmptyLiteral(ranges.map(literal))))"
    }
}

func literal(_ relation: PluralRelation) -> String {
    let modulus = relation.modulus.map { "modulus: \(Int($0)), " } ?? ""
    return "PluralRelation(operand: \(literal(relation.operand)), \(modulus)comparison: \(literal(relation.comparison)))"
}

func literal(_ spacing: Spacing) -> String {
    switch spacing {
    case .none: ".none"
    case .asciiSpace: ".asciiSpace"
    case .nonBreakingSpace: ".nonBreakingSpace"
    case .narrowNonBreakingSpace: ".narrowNonBreakingSpace"
    }
}

func literal(_ name: FullName) -> String {
    let forms = PluralCategory.allCases.compactMap { category in
        name.byCategory[category].map { ".\(category.rawValue): \(quote($0))" }
    }

    let byCategory = forms.isEmpty ? "" : ", byCategory: [\(forms.joined(separator: ", "))]"
    return "CurrencyFullName(other: \(quote(name.other))\(byCategory))"
}

func literal(_ rule: PluralRule) -> String {
    let groups = rule.orOfAndGroups.map { nonEmptyLiteral($0.map(literal)) }
    return "PluralRule(orOfAndGroups: \(nonEmptyLiteral(groups)))"
}

func quote(_ string: String) -> String {
    var escaped = ""
    for scalar in string.unicodeScalars {
        switch scalar {
        case "\\": escaped += "\\\\"
        case "\"": escaped += "\\\""
        case _ where scalar.value < 0x20 || scalar.value > 0x7E:
            escaped += "\\u{\(String(scalar.value, radix: 16, uppercase: true))}"
        default:
            escaped.unicodeScalars.append(scalar)
        }
    }
    return "\"\(escaped)\""
}

var numberFormatLines: [String] = []
var currencyBlocks: [String] = []
var fullNameBlocks: [String] = []
var pluralRuleBlocks: [String] = []

let ruleText = cardinalRuleText()
checkEveryLocaleAgainstItsSamples(ruleText)

for language in languages {
    let rules = pluralRules(for: language, in: ruleText).map { category, rule in
        "            .\(category.rawValue): \(literal(rule)),"
    }

    // A language that draws no plural distinctions, such as Japanese, has rules for no category at
    // all: every amount takes `other`.
    guard !rules.isEmpty else {
        pluralRuleBlocks.append("        \(quote(language)): [:],")
        continue
    }

    pluralRuleBlocks.append("""
            \(quote(language)): [
    \(rules.joined(separator: "\n"))
            ],
    """)
}

for locale in locales {
    let n = numbers(locale)
    let symbols = n["symbols-numberSystem-latn"] as! [String: String]
    let formats = n["currencyFormats-numberSystem-latn"] as! [String: Any]
    let standard = formats["standard"] as! String
    let accounting = formats["accounting"] as! String
    let spacingRule = formats["currencySpacing"] as! [String: Any]
    let afterCurrency = spacingRule["afterCurrency"] as! [String: String]
    let insertBetween = afterCurrency["insertBetween"] ?? " "

    let parsed = parse(standard: standard, accounting: accounting)
    let fullName = fullNameLayout(formats.compactMapValues { $0 as? String }, locale: locale)

    // ISO code is always letters, so it takes the insertion (or the pattern's literal spacing).
    let isoSpacing = spacing(for: "AAA", placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)

    numberFormatLines.append("""
            \(quote(locale)): LocaleNumberFormat(
                decimalSeparator: \(quote(symbols["decimal"]!)),
                groupingSeparator: \(quote(symbols["group"]!)),
                minusSign: \(quote(symbols["minusSign"] ?? "-")),
                primaryGroupingSize: \(parsed.primaryGroupingSize),
                secondaryGroupingSize: \(parsed.secondaryGroupingSize),
                pattern: \(patternLiteral(placement: parsed.placement, accountingNegative: parsed.accountingNegative)),
                fullNamePattern: \(fullName.literal),
                isoCodeSpacing: \(quote(isoSpacing)),
                fullNameSpacing: \(literal(fullName.spacing))
            ),
    """)

    var entries: [String] = []
    for (code, fields) in currencies(locale).sorted(by: { $0.key < $1.key }) {
        let symbol = fields["symbol"] ?? code
        let narrow = fields["symbol-alt-narrow"] ?? symbol
        guard symbol != code || narrow != code else {
            continue   // neither form is distinct; the runtime falls back to the code
        }
        let standardSpacing = spacing(for: symbol, placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)
        let narrowSpacing = spacing(for: narrow, placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)
        entries.append("            \(quote(code)): CurrencyDisplay(standardSymbol: \(quote(symbol)), standardSpacing: \(quote(standardSpacing)), narrowSymbol: \(quote(narrow)), narrowSpacing: \(quote(narrowSpacing))),")
    }

    currencyBlocks.append("""
            \(quote(locale)): [
    \(entries.joined(separator: "\n"))
            ],
    """)

    let names = fullNames(currencies(locale)).map { "            \(quote($0.code)): \(literal($0))," }

    fullNameBlocks.append("""
            \(quote(locale)): [
    \(names.joined(separator: "\n"))
            ],
    """)
}

let output = """
// Generated from CLDR \(cldrVersion) by GenerateSwiftMoneyLocalization. Do not edit by hand.
// Regenerate with: (cd Tools/cldr && npm ci) && swift run GenerateSwiftMoneyLocalization

import SwiftMoneyCore

extension MoneyLocalization {
    static let cldrVersion = \(quote(cldrVersion))

    static let numberFormats: [String: LocaleNumberFormat] = [
    \(numberFormatLines.joined(separator: "\n"))
    ]

    static let currencyDisplays: [String: [String: CurrencyDisplay]] = [
    \(currencyBlocks.joined(separator: "\n"))
    ]

    /// What each locale calls a currency, by plural category. A currency CLDR does not name in a
    /// locale is absent.
    package static let currencyFullNames: [String: [CurrencyCode: CurrencyFullName]] = [
    \(fullNameBlocks.joined(separator: "\n"))
    ]

    /// Each language's plural rules, in the order CLDR resolves them. A language with no rule for a
    /// category takes `other`, which never carries one.
    package static let pluralRules: [String: [PluralCategory: PluralRule]] = [
    \(pluralRuleBlocks.joined(separator: "\n"))
    ]
}
"""

try? FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true
)
try! output.write(toFile: outputPath, atomically: true, encoding: .utf8)
print("Wrote \(outputPath) from CLDR \(cldrVersion) for locales: \(locales.joined(separator: ", "))")

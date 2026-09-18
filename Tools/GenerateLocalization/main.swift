// A dev-only tool. Reads the pinned CLDR JSON (fetched via npm into Tools/cldr/node_modules) and emits
// the Swift data tables that SwiftMoneyLocalization composes into a MoneyFormat. Not part of any library
// product; run with `swift run GenerateSwiftMoneyLocalization` after `npm ci` in Tools/cldr.
//
// This tool builds against the module it writes into, so a generated file that does not compile stops
// the tool that would replace it: restore the last good one with `git checkout` before rerunning.
//
// CLDR encodes currency spacing two ways: a literal space inside the format pattern (e.g. the NBSP in
// "#,##0.00 ¤"), and a currencySpacing rule that inserts a space between the number and a symbol whose
// touching character is neither a Unicode Symbol nor a separator (so ISO codes like "GBP" get a space,
// but "£"/"€" do not). This tool resolves that rule at generation time — using the full Swift Unicode
// tables, which Embedded lacks — and bakes the resulting spacing string into the data, so the runtime
// target needs no Unicode-category lookups.

import CLDRPluralParsing
import Foundation
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
var pluralRuleBlocks: [String] = []

let ruleText = cardinalRuleText()

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

    // ISO code is always letters, so it takes the insertion (or the pattern's literal spacing).
    let isoSpacing = spacing(for: "AAA", placement: parsed.placement, patternSpacing: parsed.patternSpacing, insertBetween: insertBetween)

    numberFormatLines.append("""
            \(quote(locale)): LocaleNumberFormat(
                decimalSeparator: \(quote(symbols["decimal"]!)),
                groupingSeparator: \(quote(symbols["group"]!)),
                minusSign: \(quote(symbols["minusSign"] ?? "-")),
                primaryGroupingSize: \(parsed.primaryGroupingSize),
                secondaryGroupingSize: \(parsed.secondaryGroupingSize),
                placement: \(parsed.placement.rawValue),
                isoCodeSpacing: \(quote(isoSpacing)),
                accountingNegative: \(parsed.accountingNegative)
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

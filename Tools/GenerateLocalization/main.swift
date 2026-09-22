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

import CLDRCurrencyPatterns
import CLDRLocaleSkips
import CLDRPluralParsing
import Foundation
import SwiftMoneyCore
import SwiftMoneyLocalization

// `ar-EG` and `nl` are here to be left out, not to be emitted: one writes Arabic-Indic digits and the
// other arranges its own negatives, so they exercise the skip path and keep the committed report from
// being empty while the covered set is still listed by hand.
let candidates = ["en", "en-GB", "de", "fr", "ja", "sw", "si", "ro", "ar-EG", "nl"]

let repoRoot = FileManager.default.currentDirectoryPath
let cldrMain = "\(repoRoot)/Tools/cldr/node_modules/cldr-numbers-full/main"
let cldrSupplemental = "\(repoRoot)/Tools/cldr/node_modules/cldr-core/supplemental"
let outputPath = "\(repoRoot)/Sources/SwiftMoneyLocalization/Generated/CLDRTables.swift"

// Beside the tables, so that regenerating and diffing that directory keeps the account of what was
// left out as honest as the data itself.
let reportPath = "\(repoRoot)/Sources/SwiftMoneyLocalization/Generated/UnsupportedLocales.md"

// Plural rules are published per language, so a region keeps its language's rules.
func language(of locale: String) -> String {
    String(locale.prefix { $0 != "-" })
}

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

// The CLDR release the tables are built from, read from the installed packages rather than written in
// here, so a version bump cannot leave them labelled with the release before it.
//
// Both packages carry one release of the same data, so a mismatch means one was bumped without the
// other and the tables would be a mixture of two releases. Refused rather than reported, since a
// mixture is not something to label accurately.
let cldrVersion: String = {
    let versions = ["cldr-core", "cldr-numbers-full"].map { package -> String in
        let path = "\(repoRoot)/Tools/cldr/node_modules/\(package)/package.json"
        guard let version = json(path)["version"] as? String else {
            fatalError("Could not read the CLDR version from \(path)")
        }
        return version
    }

    guard let version = versions.first, versions.allSatisfy({ $0 == version }) else {
        fatalError("The installed CLDR packages are different releases: \(versions)")
    }

    return version
}()

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

let integerNumberChars: Set<Character> = ["#", "0", ",", "."]

struct ParsedPattern {
    let side: CurrencySide
    let patternSpacing: String
    let grouping: GroupSizes
    let accountingNegative: String
}

func parse(standard: String, accounting: String) throws(LocaleSkip) -> ParsedPattern {
    let positive = String(standard.split(separator: ";").first ?? Substring(standard))

    // `CurrencySide` reads the same two positions, so a pattern it can place is one with both of these.
    guard
        let side = CurrencySide(pattern: standard),
        let symbolIndex = positive.firstIndex(of: "¤"),
        let firstNumber = positive.firstIndex(where: { integerNumberChars.contains($0) })
    else {
        throw .noCurrencyPlaceholder(pattern: standard)
    }

    let patternSpacing: String
    switch side {
    case .leading:
        // Chars between ¤ and the first number character.
        patternSpacing = String(positive[positive.index(after: symbolIndex) ..< firstNumber])
    case .trailing:
        // Chars between the last number character and ¤.
        guard let lastNumber = positive.lastIndex(where: { integerNumberChars.contains($0) }) else {
            throw .noCurrencyPlaceholder(pattern: standard)
        }
        patternSpacing = String(positive[positive.index(after: lastNumber) ..< symbolIndex])
    }

    // Accounting wraps negatives in parentheses when its negative subpattern does, else it uses a minus.
    let negativeSubpattern = accounting.split(separator: ";").dropFirst().first ?? ""
    let accountingNegative = negativeSubpattern.contains("(") ? ".parentheses" : ".minusSign"

    return ParsedPattern(
        side: side,
        patternSpacing: patternSpacing,
        grouping: GroupSizes(pattern: standard),
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
func currencyAffix(side: CurrencySide) -> (prefix: [String], suffix: [String]) {
    side == .leading
        ? (prefix: [".currency", ".currencySpacing"], suffix: [])
        : (prefix: [], suffix: [".currencySpacing", ".currency"])
}

// A locale's three arrangements. A locale whose standard pattern arranges a negative itself is
// skipped, so a negative here is the positive arrangement with a sign in front, which is CLDR's own
// default; the accounting form either wraps that in parentheses or falls back to the same minus.
func patternLiteral(side: CurrencySide, accountingNegative: String) -> String {
    let body = currencyAffix(side: side)
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

// The index of a pattern among the distinct ones, adding it if it is new. Patterns repeat heavily
// across locales, so a locale's record holds an index and the pattern itself is written once.
func index(of literal: String, in table: inout [String]) -> UInt16 {
    if let existing = table.firstIndex(of: literal) {
        return UInt16(existing)
    }

    table.append(literal)

    return UInt16(table.count - 1)
}

// MARK: - Currency spacing (resolved here, baked into the data)

// The string CLDR inserts between a currency and the digits, refusing a locale whose rule this tool
// cannot resolve ahead of time: one spacing the two sides differently, or matching by sets other than
// those `isSymbolOrSeparator` implements. Those sets are narrower than the `[:^S:]` LDML documents as
// the default, the code following the published data rather than the specification.
func currencySpacingInsertion(_ rule: [String: Any], locale: String) throws(LocaleSkip) -> String {
    // Escaped and ordered, because every gap CLDR inserts is a space of some width and two of them are
    // indistinguishable in a message that prints them raw.
    func describe(_ side: [String: String]) -> String {
        ["currencyMatch", "surroundingMatch", "insertBetween"]
            .map { "\($0) \(side[$0].map(quote) ?? "absent")" }
            .joined(separator: ", ")
    }

    guard
        let before = rule["beforeCurrency"] as? [String: String],
        let after = rule["afterCurrency"] as? [String: String]
    else {
        fatalError("\(locale) publishes no currency spacing rule")
    }

    guard before == after else {
        throw .asymmetricCurrencySpacing(before: describe(before), after: describe(after))
    }

    guard
        after["currencyMatch"] == "[[:^S:]&[:^Z:]]",
        after["surroundingMatch"] == "[:digit:]"
    else {
        throw .unreadableCurrencySpacing(rule: describe(after))
    }

    guard let insertBetween = after["insertBetween"] else {
        fatalError("\(locale) gives its currency spacing rule nothing to insert")
    }

    return insertBetween
}

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
func spacing(for symbol: String, side: CurrencySide, patternSpacing: String, insertBetween: String) -> String {
    if !patternSpacing.isEmpty {
        return patternSpacing
    }
    let boundary = side == .leading ? symbol.last : symbol.first
    guard let boundary, !isSymbolOrSeparator(boundary) else {
        return ""
    }
    return insertBetween
}

// The same gap as a `Spacing` case, skipping a locale whose gap is not one CLDR uses for this join:
// the packed record holds a two-digit code, so only the four cases are representable.
func spacingCode(
    for symbol: String,
    side: CurrencySide,
    patternSpacing: String,
    insertBetween: String
) throws(LocaleSkip) -> Spacing {
    let gap = spacing(for: symbol, side: side, patternSpacing: patternSpacing, insertBetween: insertBetween)
    guard let spacing = Spacing(rendering: gap) else {
        throw .unrepresentableGap(gap, symbol: symbol)
    }
    return spacing
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
func fullNameLayout(_ patterns: [String: String], locale: String) throws(LocaleSkip) -> (literal: String, spacing: Spacing) {
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
        throw .multipleNameGaps(spacings)
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

// One language's rules and the values CLDR samples them with. `other` carries no condition, so it has
// no rule: the runtime falls back to it when no other rule holds.
struct LanguageRules {
    let rules: [(PluralCategory, PluralRule)]
    let samples: [(category: PluralCategory, sample: PluralSample)]

    var byCategory: [PluralCategory: PluralRule] {
        Dictionary(uniqueKeysWithValues: rules.map { ($0.0, $0.1) })
    }
}

// One language's rules, read from CLDR's text. Parsed here alone, so that the run that checks the
// rules and the run that packs them cannot read the text two different ways.
//
// The two failures are different in kind. A relation CLDR's grammar allows and this engine does not
// model is a shape the tables lack, so the language's locales are skipped and the rest of the data
// still builds. Anything else is this tool misreading CLDR, so it stops the run.
func languageRules(for language: String, in text: [String: [String: String]]) throws(LocaleSkip) -> LanguageRules {
    guard let published = text[language] else {
        throw .noPluralRules(language: language)
    }

    var rules: [(PluralCategory, PluralRule)] = []
    var samples: [(category: PluralCategory, sample: PluralSample)] = []

    for category in PluralCategory.allCases {
        guard let line = published["pluralRule-count-\(category.rawValue)"] else {
            continue
        }

        let parsed = try readRule(line, language: language, category: category)
        parsed.rule.map { rules.append((category, $0)) }
        samples += parsed.samples.map { (category, $0) }
    }

    return LanguageRules(rules: rules, samples: samples)
}

func readRule(
    _ line: String,
    language: String,
    category: PluralCategory
) throws(LocaleSkip) -> PluralRuleText {
    do {
        return try PluralRuleText(parsing: line)
    } catch .unsupportedRelation(let relation) {
        throw .unsupportedPluralRule(language: language, relation: relation)
    } catch {
        fatalError("Could not read \(language)'s rule for \(category.rawValue): \(line): \(error)")
    }
}

// CLDR publishes, beside each rule, the values that rule is meant to cover. Running them back
// through the rules checks the reading of every language CLDR knows, not just the ones a locale here
// needs, so a rule this tool would misread surfaces now rather than when that language is added.
//
// A sample that resolves to the wrong category is a fault in the rule engine rather than a shape a
// locale lacks, so it stops the run even though an unmodelled relation does not.
func checkEveryLanguageAgainstItsSamples(_ text: [String: [String: String]]) {
    var checked = 0
    var unmodelled = 0

    for language in text.keys.sorted() {
        guard let parsed = try? languageRules(for: language, in: text) else {
            unmodelled += 1
            continue
        }

        let rules = parsed.byCategory
        for (category, sample) in parsed.samples {
            let operands = PluralOperandValues(minorUnits: sample.minorUnits, unitScale: sample.unitScale)
            let resolved = PluralCategory.allCases.first { rules[$0]?.matches(operands) == true } ?? .other

            guard resolved == category else {
                fatalError("\(language) \(sample) resolves to \(resolved.rawValue), CLDR publishes it under \(category.rawValue)")
            }
        }

        checked += parsed.samples.count
    }

    print("Checked \(checked) CLDR samples across \(text.count) languages, \(unmodelled) unmodelled.")
}

// MARK: - Swift emission

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


// The blob as a Swift string literal. Its bytes are valid UTF-8 by construction — printable digits in
// the sections, the pool's own text in the pool — so everything but a literal's own punctuation passes
// through as it is, which keeps the generated source close to the size of the data it carries.
func blobLiteral(_ blob: [UInt8]) -> String {
    var escaped: [UInt8] = Array("\"".utf8)

    for byte in blob {
        switch byte {
        case UInt8(ascii: "\\"), UInt8(ascii: "\""):
            escaped.append(UInt8(ascii: "\\"))
            escaped.append(byte)
        case 0 ..< 0x20, 0x7F:
            escaped.append(contentsOf: "\\u{\(String(byte, radix: 16, uppercase: true))}".utf8)
        default:
            escaped.append(byte)
        }
    }

    escaped.append(UInt8(ascii: "\""))

    return String(decoding: escaped, as: UTF8.self)
}

// A symbol CLDR publishes for every locale. Missing means the data has changed shape, which is a fault
// in how this tool reads it rather than something to format around.
func required(_ symbols: [String: String], _ field: String, in locale: String) -> String {
    guard let value = symbols[field] else {
        fatalError("\(locale) publishes no \(field) symbol")
    }

    return value
}

// MARK: - Deciding

// Everything one locale contributes, read and resolved without writing anything down. A locale that
// throws here is left out of the tables entirely and keeps the runtime's ICU fallback.
func tables(for locale: String, unusableLanguages: [String: LocaleSkip]) throws(LocaleSkip) -> LocaleTables {
    if let skip = unusableLanguages[language(of: locale)] {
        throw skip
    }

    let n = numbers(locale)
    let symbols = n["symbols-numberSystem-latn"] as! [String: String]
    let formats = n["currencyFormats-numberSystem-latn"] as! [String: Any]
    let standard = formats["standard"] as! String
    let accounting = formats["accounting"] as! String
    let spacingRule = formats["currencySpacing"] as! [String: Any]

    // Read before the pattern, which answers a narrower question: it takes the part before the first
    // `;` and looks only between the currency and the nearest digit, so it would pass over all three
    // of these without noticing. The `-latn` keys above are read whatever the locale's own system is,
    // which is exactly why the system has to be checked rather than assumed.
    if let unsupported = UnsupportedNumberFormat(
        standardPattern: standard,
        defaultNumberingSystem: n["defaultNumberingSystem"] as! String
    ) {
        throw .unrepresentableNumberFormat(unsupported)
    }

    for field in PatternField.allCases {
        let pattern = field == .standard ? standard : accounting
        if let unsupported = UnsupportedPattern(
            pattern: pattern,
            letterSymbolPattern: formats["\(field.rawValue)-alphaNextToNumber"] as? String
        ) {
            throw .unrepresentablePattern(unsupported, field: field)
        }
    }

    let insertBetween = try currencySpacingInsertion(spacingRule, locale: locale)
    let parsed = try parse(standard: standard, accounting: accounting)
    let fullName = try fullNameLayout(formats.compactMapValues { $0 as? String }, locale: locale)
    let gap = { (symbol: String) throws(LocaleSkip) -> Spacing in
        try spacingCode(
            for: symbol,
            side: parsed.side,
            patternSpacing: parsed.patternSpacing,
            insertBetween: insertBetween
        )
    }

    var unusableCodes: Set<String> = []

    // Sorted, because a dictionary's order varies between runs and the order strings reach the pool in
    // decides the bytes: the committed tables have to come out the same on any machine, which is what
    // the CLDR workflow checks by regenerating them.
    var displays: [LocaleTables.Display] = []
    for (code, fields) in currencies(locale).sorted(by: { $0.key < $1.key }) {
        let symbol = fields["symbol"] ?? code
        let narrow = fields["symbol-alt-narrow"] ?? symbol
        guard symbol != code || narrow != code else {
            continue   // neither form is distinct; the runtime falls back to the code
        }
        guard let currencyCode = CurrencyCode(string: code) else {
            unusableCodes.insert(code)
            continue
        }

        displays.append(LocaleTables.Display(
            code: currencyCode,
            standardSymbol: symbol,
            standardSpacing: try gap(symbol),
            narrowSymbol: narrow,
            narrowSpacing: try gap(narrow)
        ))
    }

    let names: [LocaleTables.FullName] = fullNames(currencies(locale)).compactMap { name in
        guard let code = CurrencyCode(string: name.code) else {
            unusableCodes.insert(name.code)
            return nil
        }

        return LocaleTables.FullName(
            code: code,
            other: name.other,
            overrides: PluralCategory.allCases.compactMap { category in
                name.byCategory[category].map { (category, $0) }
            }
        )
    }

    return LocaleTables(
        decimalSeparator: required(symbols, "decimal", in: locale),
        groupingSeparator: required(symbols, "group", in: locale),
        minusSign: symbols["minusSign"] ?? "-",
        // ISO code is always letters, so it takes the insertion (or the pattern's literal spacing).
        isoCodeSpacing: try gap("AAA"),
        primaryGroupingSize: UInt8(parsed.grouping.primary),
        secondaryGroupingSize: UInt8(parsed.grouping.secondary),
        fullNameSpacing: fullName.spacing,
        pattern: patternLiteral(side: parsed.side, accountingNegative: parsed.accountingNegative),
        fullNamePattern: fullName.literal,
        displays: displays,
        fullNames: names,
        unusableCurrencyCodes: unusableCodes
    )
}

// Every candidate language read once, split into the ones a locale can be built on and the ones it
// cannot. A language serves many locales, so reading its rules for each of them would repeat the work
// hundreds of times over.
func pluralRuleSets(
    among locales: [String],
    in text: [String: [String: String]]
) -> (usable: [String: LanguageRules], unusable: [String: LocaleSkip]) {
    var usable: [String: LanguageRules] = [:]
    var unusable: [String: LocaleSkip] = [:]

    for language in locales.map(language(of:)).uniqued() {
        do {
            usable[language] = try languageRules(for: language, in: text)
        } catch {
            unusable[language] = error
        }
    }

    return (usable, unusable)
}

// MARK: - Packing

// One decided locale written into the shared pool and pattern tables. Separate from deciding so that
// nothing of a locale reaches them until the whole of it is known to be representable.
func pack(
    _ tables: LocaleTables,
    locale: String,
    into pool: inout StringPool,
    patterns: inout [String],
    fullNamePatterns: inout [String]
) -> PackedLocale {
    let numberFormat = PackedLocale.NumberFormat(
        decimalSeparator: pool.insert(tables.decimalSeparator),
        groupingSeparator: pool.insert(tables.groupingSeparator),
        minusSign: pool.insert(tables.minusSign),
        isoCodeSpacing: tables.isoCodeSpacing,
        primaryGroupingSize: tables.primaryGroupingSize,
        secondaryGroupingSize: tables.secondaryGroupingSize,
        fullNameSpacing: tables.fullNameSpacing,
        patternIndex: index(of: tables.pattern, in: &patterns),
        fullNamePatternIndex: index(of: tables.fullNamePattern, in: &fullNamePatterns)
    )

    let displays = tables.displays.map { display in
        PackedLocale.Display(
            code: display.code,
            standardSymbol: pool.insert(display.standardSymbol),
            standardSpacing: display.standardSpacing,
            narrowSymbol: pool.insert(display.narrowSymbol),
            narrowSpacing: display.narrowSpacing
        )
    }

    let names = tables.fullNames.map { name in
        PackedLocale.FullName(
            code: name.code,
            other: pool.insert(name.other),
            overrides: name.overrides.map { ($0.category, pool.insert($0.name)) }
        )
    }

    // Both runs are binary searched at runtime, so they are laid out in the order that search assumes.
    return PackedLocale(
        key: pool.insert(locale),
        numberFormat: numberFormat,
        displays: displays.sorted { $0.code.compactValue < $1.code.compactValue },
        fullNames: names.sorted { $0.code.compactValue < $1.code.compactValue }
    )
}

var pool = StringPool(base: CLDRBlob.headerWidth)
var patterns: [String] = []
var fullNamePatterns: [String] = []
var packedLocales: [PackedLocale] = []
var packedPluralLanguages: [PackedPluralLanguage] = []

let ruleText = cardinalRuleText()
checkEveryLanguageAgainstItsSamples(ruleText)

// The locale section is binary searched by UTF-8 bytes, so the tables hold the locales in that order
// rather than in the order this tool lists them.
let ordered = candidates.sorted { $0.utf8.lexicographicallyPrecedes($1.utf8) }
let pluralRules = pluralRuleSets(among: ordered, in: ruleText)

var emitted: [(locale: String, tables: LocaleTables)] = []
var skipped: [SkippedLocale] = []

for locale in ordered {
    do {
        emitted.append((locale, try tables(for: locale, unusableLanguages: pluralRules.unusable)))
    } catch {
        skipped.append(SkippedLocale(locale: locale, skip: error))
    }
}

// Derived from what was emitted rather than from the candidates, so the tables carry rules only for
// languages a locale in them actually resolves against.
let languages = emitted.map { language(of: $0.locale) }.uniqued()

// Sorted by UTF-8 bytes so the blob comes out the same on any machine; the section is decoded whole, so
// the order is for that reproducibility rather than for a search. A language that draws no plural
// distinctions, such as Japanese, has rules for no category and takes `other` for every amount.
for language in languages.sorted(by: { $0.utf8.lexicographicallyPrecedes($1.utf8) }) {
    packedPluralLanguages.append(PackedPluralLanguage(
        key: pool.insert(language),
        rules: pluralRules.usable[language, default: LanguageRules(rules: [], samples: [])].rules
    ))
}

for (locale, tables) in emitted {
    packedLocales.append(pack(
        tables,
        locale: locale,
        into: &pool,
        patterns: &patterns,
        fullNamePatterns: &fullNamePatterns
    ))
}

let blob = PackedTables(locales: packedLocales, pool: pool, pluralLanguages: packedPluralLanguages).encoded()

let report = SkipReport(
    cldrVersion: cldrVersion,
    candidates: candidates.count,
    skipped: skipped,
    unusableCurrencyCodes: emitted.reduce(into: Set<String>()) { $0.formUnion($1.tables.unusableCurrencyCodes) }
)

// MARK: - Swift emission

let output = """
// Generated from CLDR \(cldrVersion) by GenerateSwiftMoneyLocalization. Do not edit by hand.
// Regenerate with: (cd Tools/cldr && npm ci) && swift run GenerateSwiftMoneyLocalization

import SwiftMoneyCore

// The locale data is packed into one string literal rather than written out as Swift values: the
// equivalent literals defeat the compiler well before every CLDR locale is covered, where a literal of
// this size costs it nothing. `CLDRBlob` reads it, and the layout is documented on the types that do.
//
// What stays a Swift value is what there is little of: the distinct patterns a locale's record indexes.
// Those are built in `@_optimize(none)` functions because under `-O` the Swift 6.3.2 optimizer (Xcode
// 26.5) spends many minutes on literal tables, enough to stall CI; skipping optimization of the builder
// avoids it. The data is identical either way and built once.
extension MoneyLocalization {
    static let cldrVersion = \(quote(cldrVersion))

    /// The packed CLDR tables every lookup reads.
    package static let cldr = CLDRBlob(
        bytes: packedTables,
        patterns: makePatterns(),
        fullNamePatterns: makeFullNamePatterns()
    )

    private static let packedTables: StaticString = \(blobLiteral(blob))

    /// The distinct arrangements of a currency symbol, a sign and the digits, in the order a locale's
    /// record counts them.
    @_optimize(none) private static func makePatterns() -> [MoneyFormatPattern] {
        [
\(patterns.map { "            \($0)," }.joined(separator: "\n"))
        ]
    }

    /// The distinct arrangements of a currency's full name beside the digits, in the same order.
    @_optimize(none) private static func makeFullNamePatterns() -> [FullNameLayout] {
        [
\(fullNamePatterns.map { "            \($0)," }.joined(separator: "\n"))
        ]
    }
}
"""

try? FileManager.default.createDirectory(
    atPath: (outputPath as NSString).deletingLastPathComponent,
    withIntermediateDirectories: true
)
try! output.write(toFile: outputPath, atomically: true, encoding: .utf8)
try! report.rendered.write(toFile: reportPath, atomically: true, encoding: .utf8)
print("""
    Wrote \(outputPath) from CLDR \(cldrVersion)
    Covered \(report.emitted) of \(candidates.count) locales; \(skipped.count) skipped, see \(reportPath)
    Packed tables: \(blob.count) bytes, \(patterns.count) pattern(s), \(fullNamePatterns.count) full-name layout(s)
    """)

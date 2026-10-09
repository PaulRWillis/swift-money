/// A locale name with no CLDR folder of its own, and the built locale TR35's lookup reaches from it.
///
/// Other modules get one only from ``LocaleInheritance/resolvedNames(for:)``.
///
/// ```swift
/// let name = inheritance.resolvedNames(for: built)[0]
/// name.name                     // "zh-TW"
/// name.locale.group.shortName   // "zh-Hant"
/// ```
package struct ResolvedName<Value> {
    /// The name, spelled as CLDR spells it.
    package let name: String

    /// The built locale the name reaches.
    package let locale: BuiltLocale<Value>

    /// Creates a record of a name and the locale it reaches.
    ///
    /// - Parameters:
    ///   - name: The name, spelled as CLDR spells it.
    ///   - locale: The built locale the name reaches.
    init(name: String, locale: BuiltLocale<Value>) {
        self.name = name
        self.locale = locale
    }
}

extension ResolvedName: Sendable where Value: Sendable {}

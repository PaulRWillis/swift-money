import SwiftMoneyLocalization

extension LocaleInheritance {
    /// Every name a locale is found under so far, keyed as the runtime lookup compares names.
    private typealias Keys<Value> = [FoldedLocaleName: ResolvedName<Value>]

    /// Returns the names with no folder that the runtime lookup would miss, each with the built
    /// locale TR35's lookup reaches from it.
    ///
    /// Three kinds are filed, in order. Places CLDR names (`zh-TW`) whose lookup reaches a built
    /// locale the runtime chain wouldn't. Then the language's own script (`ha-Latn`), filed under the
    /// language when a place implies another script. Then each place spelled with the script it
    /// implies (`ha-Latn-GH`), where the chain would miss.
    ///
    /// ```swift
    /// inheritance.resolvedNames(for: built).map(\.name)  // ["ha-Latn", "ha-Latn-GH", "zh-TW", …]
    /// ```
    ///
    /// - Parameter built: Every group the generator built, with its value.
    /// - Returns: The names to file, in the order the runtime searches them.
    /// - Complexity: O(*n* log *n*), where *n* is the number of names CLDR mentions.
    package func resolvedNames<Value>(for built: [BuiltLocale<Value>]) -> [ResolvedName<Value>] {
        let builtByGroup = Dictionary(built.map { ($0.group, $0) }, uniquingKeysWith: { first, _ in first })
        let builtNames = built.flatMap { locale in
            locale.group.names.map { (FoldedLocaleName($0), ResolvedName(name: $0, locale: locale)) }
        }
        let initial = Keys(builtNames, uniquingKeysWith: { first, _ in first })

        let filed = filingPlacesWithScript(
            filingOwnScriptAliases(filingPlaces(initial, built: builtByGroup)),
            built: builtByGroup
        )

        return filed
            .filter { initial[$0.key] == nil }
            .map(\.value)
            .sorted { LocaleLookupOrder.precedes($0.name, $1.name) }
    }

    /// Returns the places CLDR names whose TR35 lookup reaches a locale the generator didn't build.
    ///
    /// ```swift
    /// inheritance.placesReachingUnbuiltLocales(for: built)  // ["pa-IN", …]
    /// ```
    ///
    /// - Parameter built: Every group the generator built, with its value.
    /// - Returns: The places, in the order the runtime searches names.
    /// - Complexity: O(*n* log *n*), where *n* is the number of names CLDR mentions.
    package func placesReachingUnbuiltLocales<Value>(for built: [BuiltLocale<Value>]) -> [String] {
        let builtGroups = Set(built.map(\.group))

        return places(spokenIn: built).filter { !builtGroups.contains(group(reachedFrom: $0)) }
    }

    /// Files each place CLDR names, `L-R` with no folder, where the runtime chain misses the locale
    /// TR35's lookup reaches.
    ///
    /// - Parameters:
    ///   - keys: The names filed so far.
    ///   - built: Every built locale, by its group.
    /// - Returns: `keys` with the places added.
    private func filingPlaces<Value>(_ keys: Keys<Value>, built: [LocaleGroup: BuiltLocale<Value>]) -> Keys<Value> {
        filing(places(spokenIn: Array(built.values)), into: keys, built: built)
    }

    /// Files the language's own script, `L-S₀`, under the language, for each place whose implied
    /// script isn't the language's own.
    ///
    /// - Parameter keys: The names filed so far.
    /// - Returns: `keys` with the aliases added.
    private func filingOwnScriptAliases<Value>(_ keys: Keys<Value>) -> Keys<Value> {
        keys.values.reduce(into: keys) { keys, entry in
            let subtags = LocaleSubtags(entry.name)

            guard
                let place = Place(subtags),
                let ownScript = ownScript(of: subtags.language),
                LocaleSubtags(scripts.withImpliedScript(place.name)).script != ownScript,
                let language = keys[FoldedLocaleName(String(subtags.language))]
            else {
                return
            }

            let alias = "\(subtags.language)-\(ownScript)"
            let folded = FoldedLocaleName(alias)

            if keys[folded] == nil {
                keys[folded] = ResolvedName(name: alias, locale: language.locale)
            }
        }
    }

    /// Files each place spelled with the script it implies, `L-S-R`, where no key or group holds that
    /// spelling and the runtime chain misses the locale TR35's lookup reaches.
    ///
    /// - Parameters:
    ///   - keys: The names filed so far.
    ///   - built: Every built locale, by its group.
    /// - Returns: `keys` with the spellings added.
    private func filingPlacesWithScript<Value>(
        _ keys: Keys<Value>,
        built: [LocaleGroup: BuiltLocale<Value>]
    ) -> Keys<Value> {
        let spellings = keys.values.compactMap { entry -> String? in
            guard Place(LocaleSubtags(entry.name)) != nil else {
                return nil
            }

            let spelling = scripts.withImpliedScript(entry.name)

            guard
                spelling != entry.name,
                keys[FoldedLocaleName(spelling)] == nil,
                group(named: spelling) == nil
            else {
                return nil
            }

            return spelling
        }

        return filing(spellings.sorted(by: LocaleLookupOrder.precedes), into: keys, built: built)
    }

    /// Files each name whose TR35 lookup reaches a built locale the runtime chain over the keys so
    /// far misses.
    ///
    /// - Parameters:
    ///   - names: The candidate names, in the order to file them.
    ///   - keys: The names filed so far.
    ///   - built: Every built locale, by its group.
    /// - Returns: `keys` with the names added.
    private func filing<Value>(
        _ names: [String],
        into keys: Keys<Value>,
        built: [LocaleGroup: BuiltLocale<Value>]
    ) -> Keys<Value> {
        names.reduce(into: keys) { keys, name in
            guard
                let target = built[group(reachedFrom: name)],
                Self.locale(reachedBy: name, in: keys) != target.group
            else {
                return
            }

            keys[FoldedLocaleName(name)] = ResolvedName(name: name, locale: target)
        }
    }

    /// Returns every place CLDR mentions, `L-R` with no folder, in a language some built locale is in.
    ///
    /// - Parameter built: Every group the generator built, with its value.
    /// - Returns: The places, in the order the runtime searches names.
    private func places<Value>(spokenIn built: [BuiltLocale<Value>]) -> [String] {
        let languages = Set(built.flatMap { $0.group.names.map { LocaleSubtags($0).language } })

        return mentionedNames
            .filter { name in
                let subtags = LocaleSubtags(name)
                return Place(subtags) != nil && languages.contains(subtags.language) && group(named: name) == nil
            }
            .sorted(by: LocaleLookupOrder.precedes)
    }

    /// Returns the group the runtime chain reaches for a name over the keys so far.
    ///
    /// - Parameters:
    ///   - name: The name to look up.
    ///   - keys: The names filed so far.
    /// - Returns: The group of the first key the chain finds, or `nil` when it finds none.
    private static func locale<Value>(reachedBy name: String, in keys: Keys<Value>) -> LocaleGroup? {
        var chain = LocaleFallbackChain(LocaleIdentifier(name)).makeIterator()

        while let key = chain.next() {
            if let filed = keys[FoldedLocaleName(key)] {
                return filed.locale.group
            }
        }

        return nil
    }
}

extension LocaleInheritance {
    /// A place: a language and region, with no script and nothing after the region.
    private struct Place {
        /// The place's name, `L-R`.
        let name: String

        /// Reads a place from a name's subtags.
        ///
        /// - Parameter subtags: The name's subtags.
        /// - Returns: `nil` when the name has a script, no region, subtags after the region, or the
        ///   language `und`.
        init?(_ subtags: LocaleSubtags) {
            guard
                subtags.script == nil,
                subtags.rest.isEmpty,
                let region = subtags.region,
                subtags.language != LocaleInheritance.undetermined
            else {
                return nil
            }

            name = "\(subtags.language)-\(region)"
        }
    }

    /// The language subtag CLDR uses for "undetermined".
    private static let undetermined: Substring = "und"
}

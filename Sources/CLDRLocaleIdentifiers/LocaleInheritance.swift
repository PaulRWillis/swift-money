/// The CLDR locale every name reaches by Unicode TR35's lookup, over the folders CLDR publishes.
///
/// A name stops at the first group that holds it or its short name. Otherwise it follows a parent
/// locale keyed by the name, its short name, or its spelling with the implied script; otherwise it
/// truncates its spelling with the implied script: `L-S-R` to `L-S`, and `L-S` to `L` when `S` is the
/// language's own script, or to root when it isn't.
///
/// ```swift
/// let inheritance = try LocaleInheritance(
///     folders: ["und", "zh", "zh-Hant"],
///     likelySubtags: ["zh": "zh-Hans-CN", "zh-TW": "zh-Hant-TW"],
///     parentLocales: ["zh-Hant": "und"]
/// )
/// inheritance.group(reachedFrom: "zh-TW").shortName  // "zh-Hant"
/// ```
package struct LocaleInheritance: Sendable {
    /// One group per short name, in UTF-8 byte order of the short names.
    package let groups: [LocaleGroup]

    /// The scripts CLDR's likely subtags imply.
    let scripts: LikelyScripts

    /// Every name a group is found under, with its group.
    private let groupsByName: [String: LocaleGroup]

    /// Each parent locale CLDR names, keyed by the child's name.
    private let parents: [String: Parent]

    /// The root locale's group, where a lookup that runs out of names ends.
    private let root: LocaleGroup

    /// Every name CLDR's likely subtags and parent locales mention, with the language-and-script and
    /// language-and-region parts of each.
    let mentionedNames: Set<String>

    /// Creates the lookup over CLDR's folders, and checks that every lookup ends.
    ///
    /// ```swift
    /// try LocaleInheritance(folders: ["und", "en"], likelySubtags: [:], parentLocales: [:])
    /// try LocaleInheritance(folders: ["en"], likelySubtags: [:], parentLocales: [:])  // throws
    /// ```
    ///
    /// - Parameters:
    ///   - folders: The CLDR locale folder names. A name listed twice counts once.
    ///   - likelySubtags: CLDR's `likelySubtags` map, as in `"zh-TW"` to `"zh-Hant-TW"`.
    ///   - parentLocales: CLDR's `parentLocales` map, child to parent, as in `"es-JP"` to `"es-419"`.
    ///     A parent of `und` or `root` is the root locale.
    /// - Throws: ``InheritanceError/noRoot`` when no folder is `und`;
    ///   ``InheritanceError/cycle(through:)`` when the lookup from a parent locale's key comes back to
    ///   a name it already passed.
    /// - Complexity: O(*n* log *n* + *p*), where *n* is the number of folders and *p* the number of
    ///   parent locales.
    package init(
        folders: [String],
        likelySubtags: [String: String],
        parentLocales: [String: String]
    ) throws(InheritanceError) {
        let scripts = LikelyScripts(likelySubtags: likelySubtags)
        let groups = scripts.groups(of: folders)
        let groupsByName = Dictionary(
            groups.flatMap { group in group.names.map { ($0, group) } },
            uniquingKeysWith: { first, _ in first }
        )

        guard let root = groupsByName[Self.rootName] else {
            throw .noRoot
        }

        self.scripts = scripts
        self.groups = groups
        self.groupsByName = groupsByName
        self.root = root
        parents = parentLocales.mapValues(Parent.init)
        mentionedNames = Self.names(mentionedIn: likelySubtags, and: parentLocales)

        try checkEveryParentEnds()
    }

    /// Returns the group a name belongs to.
    ///
    /// ```swift
    /// inheritance.group(named: "zh-Hant-HK")?.shortName  // "zh-HK"
    /// inheritance.group(named: "zh-TW")                  // nil
    /// ```
    ///
    /// - Parameter name: A folder name or a group's short name, spelled as CLDR spells it.
    /// - Returns: The group, or `nil` when no group has that name.
    package func group(named name: String) -> LocaleGroup? {
        groupsByName[name]
    }

    /// Returns the group TR35's lookup reaches from a name.
    ///
    /// ```swift
    /// inheritance.group(reachedFrom: "zh-TW").shortName       // "zh-Hant"
    /// inheritance.group(reachedFrom: "zh-Hans-TW").shortName  // "zh"
    /// inheritance.group(reachedFrom: "ku-AM").shortName       // "und"
    /// ```
    ///
    /// - Parameter name: A hyphen-separated locale name, spelled as CLDR spells it.
    /// - Returns: The first group the lookup finds, or the root's when it finds none.
    /// - Complexity: O(*m*) per step, where *m* is the length of the name; at most one step per
    ///   subtag, plus one per parent locale on the way.
    package func group(reachedFrom name: String) -> LocaleGroup {
        switch hop(from: name) {
        case .reached(let group):
            group
        case .next(let next):
            group(reachedFrom: next)
        }
    }

    /// Returns where one step of TR35's lookup goes from a name.
    ///
    /// - Parameter name: The name the lookup has reached.
    /// - Returns: The group holding the name, its short name, or its parent's root; otherwise the next
    ///   name to look up.
    /// - Complexity: O(*m*), where *m* is the length of the name.
    private func hop(from name: String) -> Hop {
        let shortName = scripts.shortened(name)

        if let group = groupsByName[name] ?? groupsByName[shortName] {
            return .reached(group)
        }

        let withScript = scripts.withImpliedScript(name)

        switch parents[name] ?? parents[shortName] ?? parents[withScript] {
        case .locale(let parent):
            return .next(parent)
        case .root:
            return .reached(root)
        case nil:
            return truncated(name, withScript: withScript)
        }
    }

    /// Returns where TR35's truncation takes a name.
    ///
    /// - Parameters:
    ///   - name: The name to truncate.
    ///   - withScript: The name with its implied script inserted.
    /// - Returns: The name without its last subtag after any variants are gone, `L-S` for `L-R` or
    ///   `L-S-R`, or `L` for `L-S` when `S` is the language's own script; otherwise the root's group.
    /// - Complexity: O(*m*), where *m* is the length of the name.
    private func truncated(_ name: String, withScript: String) -> Hop {
        let subtags = LocaleSubtags(name)

        if !subtags.rest.isEmpty {
            return .next(LocaleSubtags(
                language: subtags.language, script: subtags.script, region: subtags.region,
                rest: Array(subtags.rest.dropLast())
            ).name)
        }

        if subtags.region != nil {
            let full = LocaleSubtags(withScript)
            return .next(
                LocaleSubtags(language: full.language, script: full.script, region: nil, rest: []).name
            )
        }

        guard let script = subtags.script, script == ownScript(of: subtags.language) else {
            return .reached(root)
        }

        return .next(String(subtags.language))
    }

    /// Returns the script CLDR implies for a bare language.
    ///
    /// - Parameter language: The language subtag.
    /// - Returns: The language's own script, or `nil` when CLDR implies none.
    func ownScript(of language: Substring) -> Substring? {
        LocaleSubtags(scripts.withImpliedScript(String(language))).script
    }

    /// Follows the lookup from every parent locale's key, and throws on the first that loops.
    ///
    /// Any other lookup ends: truncation shortens the name within two steps, and a lookup that meets a
    /// parent joins a path checked here.
    ///
    /// - Throws: ``InheritanceError/cycle(through:)`` with the first name a lookup passes twice.
    /// - Complexity: O(*p* × *d*) steps, where *p* is the number of parent locales and *d* the longest
    ///   path.
    private func checkEveryParentEnds() throws(InheritanceError) {
        for key in parents.keys.sorted() {
            var passed: Set<String> = [key]
            var name = key

            while case .next(let next) = hop(from: name) {
                guard passed.insert(next).inserted else {
                    throw .cycle(through: next)
                }
                name = next
            }
        }
    }

    /// Returns every name the likely subtags and parent locales mention, with the language-and-script
    /// and language-and-region parts of each.
    ///
    /// - Parameters:
    ///   - likelySubtags: CLDR's `likelySubtags` map.
    ///   - parentLocales: CLDR's `parentLocales` map.
    /// - Returns: Every key and value, and their `L-S` and `L-R` parts.
    /// - Complexity: O(*t*), where *t* is the total length of every key and value in both maps.
    private static func names(
        mentionedIn likelySubtags: [String: String],
        and parentLocales: [String: String]
    ) -> Set<String> {
        let whole = [likelySubtags, parentLocales].flatMap { Array($0.keys) + Array($0.values) }

        return whole.reduce(into: Set(whole)) { names, name in
            let subtags = LocaleSubtags(name)

            if let script = subtags.script {
                names.insert("\(subtags.language)-\(script)")
            }

            if let region = subtags.region {
                names.insert("\(subtags.language)-\(region)")
            }
        }
    }

    /// The name of CLDR's root locale folder, which is also the language subtag for "undetermined".
    static let rootName = "und"

    /// The older name CLDR's parent locales may give the root locale.
    private static let legacyRootName = "root"
}

extension LocaleInheritance {
    /// The locale CLDR names as another's parent.
    private enum Parent: Sendable {
        /// A named locale.
        case locale(String)

        /// The root locale, which CLDR writes as `und` or `root`.
        case root

        /// Reads a parent locale as CLDR writes it.
        ///
        /// - Parameter name: The parent's name.
        init(_ name: String) {
            let isRoot = name == LocaleInheritance.rootName || name == LocaleInheritance.legacyRootName
            self = isRoot ? .root : .locale(name)
        }
    }

    /// Where one step of TR35's lookup goes.
    private enum Hop {
        /// The lookup has found its group.
        case reached(LocaleGroup)

        /// The lookup goes on with this name.
        case next(String)
    }
}

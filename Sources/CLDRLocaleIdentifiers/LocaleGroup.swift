import SwiftMoneyLocalization

/// The CLDR locale folders one short name stands for, and every name a caller may ask for them by.
///
/// CLDR spells some locales two ways, with a script and without it where CLDR implies the script, so
/// `ff-Latn` and `ff` are one locale. A group comes only from ``LikelyScripts/groups(of:)``.
///
/// ```swift
/// let group = scripts.groups(of: ["ff", "ff-Latn"])[0]
/// group.shortName      // "ff"
/// Array(group.names)   // ["ff", "ff-Latn"]
/// ```
package struct LocaleGroup: Equatable, Hashable, Sendable {
    /// The short name: a folder's name with its script removed where CLDR's likely subtags imply it.
    package let shortName: String

    /// The folders whose short name is ``shortName``, each once, in UTF-8 byte order.
    package let folders: NonEmpty<String>

    /// Creates a group from folders already known to share a short name.
    ///
    /// - Parameters:
    ///   - shortName: The short name every folder in `folders` has.
    ///   - folders: The folders, each once, in UTF-8 byte order.
    fileprivate init(shortName: String, folders: NonEmpty<String>) {
        self.shortName = shortName
        self.folders = folders
    }

    /// Every name the locale is found under: ``shortName``, then every folder's name that differs
    /// from it, in UTF-8 byte order.
    ///
    /// ```swift
    /// Array(scripts.groups(of: ["sr-Cyrl-ME"])[0].names)  // ["sr-ME", "sr-Cyrl-ME"]
    /// ```
    package var names: NonEmpty<String> {
        NonEmpty(shortName, folders.filter { $0 != shortName })
    }

    /// Builds the group's folders and returns the value they share, each folder's failure, or the
    /// first disagreement.
    ///
    /// Stops at the first folder that disagrees with the group's first folder.
    ///
    /// ```swift
    /// // For the group of "ff" and "ff-Latn":
    /// group.resolve { _ in 1 }               // .built(1)
    /// group.resolve { $0 == "ff" ? 1 : 2 }   // .conflicting(first: "ff", second: "ff-Latn")
    /// group.resolve { (folder) throws(BuildFailure) -> Int in
    ///     throw .unbuildable(folder)
    /// }                                      // .skipped(…), one per folder
    /// ```
    ///
    /// - Parameter build: Builds one folder's value, or throws why it can't.
    /// - Returns: ``Resolution/built(_:)`` when every folder builds the same value,
    ///   ``Resolution/skipped(_:)`` when every folder fails,
    ///   ``Resolution/partlyBuilt(built:failed:)`` when the first disagreement is a failure beside a
    ///   build, and ``Resolution/conflicting(first:second:)`` when it is two different values.
    /// - Complexity: O(*n*) calls to `build`, where *n* is the number of folders.
    package func resolve<Value: Equatable, Failure: Error>(
        _ build: (String) throws(Failure) -> Value
    ) -> Resolution<Value, Failure> {
        /// Returns what building one folder came to.
        ///
        /// - Parameter folder: The folder to build.
        /// - Returns: The folder's value, or why it failed to build.
        func outcome(of folder: String) -> Result<Value, Failure> {
            Result { () throws(Failure) in try build(folder) }
        }

        let first = folders.first
        let others = folders.dropFirst()

        switch outcome(of: first) {
        case .success(let value):
            for folder in others {
                switch outcome(of: folder) {
                case .success(let other) where other == value:
                    continue
                case .success:
                    return .conflicting(first: first, second: folder)
                case .failure(let error):
                    let failure = SkippedFolder(folder: folder, error: error)
                    return .partlyBuilt(built: first, failed: failure)
                }
            }

            return .built(value)

        case .failure(let error):
            let firstSkip = SkippedFolder(folder: first, error: error)
            var skips: [SkippedFolder<Failure>] = []

            for folder in others {
                switch outcome(of: folder) {
                case .success:
                    return .partlyBuilt(built: folder, failed: firstSkip)
                case .failure(let otherError):
                    skips.append(SkippedFolder(folder: folder, error: otherError))
                }
            }

            return .skipped(NonEmpty(firstSkip, skips))
        }
    }

    /// Returns whether one identifier sorts before another by their UTF-8 bytes.
    ///
    /// - Parameters:
    ///   - lhs: An identifier to compare.
    ///   - rhs: Another identifier to compare.
    /// - Returns: `true` if `lhs` sorts before `rhs`; otherwise, `false`.
    /// - Complexity: O(*n*), where *n* is the length of the shorter identifier.
    fileprivate static func precedes(_ lhs: String, _ rhs: String) -> Bool {
        lhs.utf8.lexicographicallyPrecedes(rhs.utf8)
    }
}

extension LocaleGroup {
    /// What building a group's folders came to.
    package enum Resolution<Value, Failure: Error> {
        /// Every folder built, and all built this value.
        case built(Value)

        /// Every folder failed, each with its own failure, in the group's folder order.
        case skipped(NonEmpty<SkippedFolder<Failure>>)

        /// One folder built and another failed: the first folder to build, and the first to fail
        /// with its failure.
        case partlyBuilt(built: String, failed: SkippedFolder<Failure>)

        /// Two folders built different values: the group's first folder, and the first folder whose
        /// value differs from it.
        case conflicting(first: String, second: String)
    }

    /// A folder that failed to build, and why.
    package struct SkippedFolder<Failure: Error> {
        /// The folder's name.
        package let folder: String

        /// Why it failed to build.
        package let error: Failure

        /// Creates a record of one folder's failure.
        ///
        /// - Parameters:
        ///   - folder: The folder's name.
        ///   - error: Why it failed to build.
        fileprivate init(folder: String, error: Failure) {
            self.folder = folder
            self.error = error
        }
    }
}

extension LocaleGroup.Resolution: Equatable where Value: Equatable, Failure: Equatable {}
extension LocaleGroup.Resolution: Hashable where Value: Hashable, Failure: Hashable {}
extension LocaleGroup.Resolution: Sendable where Value: Sendable, Failure: Sendable {}
extension LocaleGroup.SkippedFolder: Equatable where Failure: Equatable {}
extension LocaleGroup.SkippedFolder: Hashable where Failure: Hashable {}
extension LocaleGroup.SkippedFolder: Sendable where Failure: Sendable {}

extension LikelyScripts {
    /// Groups CLDR locale folders by their short name.
    ///
    /// ```swift
    /// scripts.groups(of: ["ff-Latn", "ff", "en"]).map(\.shortName)  // ["en", "ff"]
    /// ```
    ///
    /// - Parameter folders: The CLDR locale folder names. A name listed twice counts once.
    /// - Returns: One group per short name, in UTF-8 byte order of the short names.
    /// - Complexity: O(*n* log *n*), where *n* is the number of folders.
    package func groups(of folders: [String]) -> [LocaleGroup] {
        Dictionary(grouping: Set(folders), by: shortened)
            .compactMap { shortName, members in
                NonEmpty(members.sorted(by: LocaleGroup.precedes)).map {
                    LocaleGroup(shortName: shortName, folders: $0)
                }
            }
            .sorted { LocaleGroup.precedes($0.shortName, $1.shortName) }
    }
}

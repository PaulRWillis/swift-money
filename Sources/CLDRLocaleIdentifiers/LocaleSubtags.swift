import SwiftMoneyLocalization

/// A hyphen-separated locale name split into its language, script, region and any subtags after
/// those.
///
/// A subtag counts as a script or a region only in its own position and shape, as
/// ``LocaleSubtagShape`` judges it, so `es-419` has a region and no script, and `ca-ES-valencia`
/// keeps `valencia` in ``rest``.
///
/// ```swift
/// let subtags = LocaleSubtags("zh-Hant-TW")
/// subtags.script  // "Hant"
/// subtags.name    // "zh-Hant-TW"
/// ```
package struct LocaleSubtags: Sendable, Equatable, Hashable {
    /// The first subtag.
    package let language: Substring

    /// The script after the language, if there is one.
    package let script: Substring?

    /// The region after the language and any script, if there is one.
    package let region: Substring?

    /// Every subtag after the language, script and region, in order.
    package let rest: [Substring]

    /// Splits a name into its subtags.
    ///
    /// ```swift
    /// LocaleSubtags("es-419").region  // "419"
    /// ```
    ///
    /// - Parameter name: A hyphen-separated locale name.
    /// - Complexity: O(*n*), where *n* is the length of `name`.
    package init(_ name: String) {
        language = name.prefix { $0 != "-" }

        var remaining = name.split(separator: "-", omittingEmptySubsequences: false).dropFirst()

        if let next = remaining.first, LocaleSubtagShape(next.utf8) == .script {
            script = next
            remaining = remaining.dropFirst()
        } else {
            script = nil
        }

        if let next = remaining.first, LocaleSubtagShape(next.utf8) == .region {
            region = next
            remaining = remaining.dropFirst()
        } else {
            region = nil
        }

        rest = Array(remaining)
    }

    /// Creates subtags from their parts.
    ///
    /// - Parameters:
    ///   - language: The language subtag.
    ///   - script: The script subtag, if there is one.
    ///   - region: The region subtag, if there is one.
    ///   - rest: The subtags after those.
    package init(language: Substring, script: Substring?, region: Substring?, rest: [Substring]) {
        self.language = language
        self.script = script
        self.region = region
        self.rest = rest
    }

    /// The subtags joined by hyphens.
    package var name: String {
        ([language] + [script, region].compactMap { $0 } + rest).joined(separator: "-")
    }
}

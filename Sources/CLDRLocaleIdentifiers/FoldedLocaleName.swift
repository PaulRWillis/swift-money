import SwiftMoneyLocalization

/// A locale name as the runtime lookup compares it, so spellings that differ only in ASCII letter
/// case or separator are one name.
///
/// ```swift
/// FoldedLocaleName("zh-Hant") == FoldedLocaleName("ZH_hant")  // true
/// ```
package struct FoldedLocaleName: Hashable, Sendable {
    /// The name's bytes, each read through ``LocaleKey/folded(_:)``.
    private let bytes: [UInt8]

    /// Creates the name a lookup key compares as.
    ///
    /// ```swift
    /// FoldedLocaleName(LocaleKey("zh_TW")) == FoldedLocaleName("zh-TW")  // true
    /// ```
    ///
    /// - Parameter key: The lookup key.
    /// - Complexity: O(*m*), where *m* is the length of the key.
    package init(_ key: LocaleKey) {
        bytes = Array(IteratorSequence(key.bytes.makeIterator()))
    }

    /// Creates the name a spelling compares as.
    ///
    /// ```swift
    /// FoldedLocaleName("EN_gb") == FoldedLocaleName("en-GB")  // true
    /// ```
    ///
    /// - Parameter name: The locale name, in any letter case, with `-` or `_` between subtags.
    /// - Complexity: O(*m*), where *m* is the length of `name`.
    package init(_ name: String) {
        self.init(LocaleKey(LocaleIdentifier(name)))
    }
}

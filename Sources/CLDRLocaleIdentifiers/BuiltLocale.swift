/// A group of CLDR locale folders and the value the generator built from them.
///
/// ```swift
/// let built = BuiltLocale(group: group, value: tables)
/// built.group.shortName  // "zh-Hant"
/// ```
package struct BuiltLocale<Value> {
    /// The group the value was built from.
    package let group: LocaleGroup

    /// The value every folder in ``group`` built.
    package let value: Value

    /// Creates a record of a group and the value built from it.
    ///
    /// - Parameters:
    ///   - group: The group the value was built from.
    ///   - value: The value every folder in `group` built.
    package init(group: LocaleGroup, value: Value) {
        self.group = group
        self.value = value
    }
}

extension BuiltLocale: Sendable where Value: Sendable {}

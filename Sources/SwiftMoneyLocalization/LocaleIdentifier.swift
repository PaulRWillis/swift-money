/// A locale identifier such as `"en-GB"`. A plain wrapper so the public API names a locale rather than
/// an untyped string; either `-` or `_` separates language and region.
public struct LocaleIdentifier: Hashable, Sendable, ExpressibleByStringLiteral {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public init(stringLiteral value: String) {
        self.value = value
    }
}

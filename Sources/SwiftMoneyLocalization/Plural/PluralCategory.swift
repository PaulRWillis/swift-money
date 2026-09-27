/// The plural form a locale uses for an amount, from CLDR's fixed set of six.
///
/// The cases are in the order CLDR resolves them: the first whose rule holds wins, and `other` stands
/// in when none does. A caller keys ``CustomCurrencyNames`` by these to name a custom currency per form.
public enum PluralCategory: String, Equatable, Hashable, Sendable, CaseIterable {
    case zero
    case one
    case two
    case few
    case many
    case other
}

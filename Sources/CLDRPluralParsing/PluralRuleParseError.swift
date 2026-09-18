/// Why a locale's plural rule text could not be read.
package enum PluralRuleParseError: Error {
    /// The text does not follow CLDR's plural rule grammar. Carries the parser's own diagnosis.
    case malformedCondition(String)

    /// The text uses a relation CLDR's grammar allows but this engine does not model, such as
    /// `within`. Carries the word that named it.
    case unsupportedRelation(String)

    /// The sample lists do not follow CLDR's sample grammar. Carries the parser's own diagnosis.
    case malformedSamples(String)
}

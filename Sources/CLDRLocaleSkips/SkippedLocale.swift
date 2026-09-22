/// One locale the generator left out, and why.
///
/// The locale sits here rather than inside ``LocaleSkip`` so that every skip names one, whatever raised
/// it: the reasons are found in helpers that do not all know which locale they are working on.
package struct SkippedLocale: Equatable, Sendable {
    /// The CLDR identifier, as the data directory spells it.
    package let locale: String

    /// What the generator could not represent.
    package let skip: LocaleSkip

    package init(locale: String, skip: LocaleSkip) {
        self.locale = locale
        self.skip = skip
    }
}

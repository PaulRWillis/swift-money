/// Which of a locale's two currency format patterns a problem was found in.
package enum PatternField: String, CaseIterable, Equatable, Sendable {
    /// The pattern an ordinary amount is written with.
    case standard

    /// The pattern an accounting presentation is written with.
    case accounting
}

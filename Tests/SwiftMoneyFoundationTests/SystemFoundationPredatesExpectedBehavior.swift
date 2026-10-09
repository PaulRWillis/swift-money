/// Returns whether this system's Foundation predates the parsing and digits the tests expect.
///
/// Below macOS 15, iOS 18, watchOS 11, tvOS 18 and visionOS 2, Foundation refuses some currency
/// text the format style writes, and gives some locales, such as `bn`, their native digits.
/// Every other system answers `false`.
///
/// ```swift
/// withKnownIssue("Foundation refuses this text") {
///     #expect(try strategy.parse(text) == amount)
/// } when: {
///     systemFoundationPredatesExpectedBehavior()
/// }
/// ```
///
/// - Returns: `true` on a system below those releases; otherwise, `false`.
func systemFoundationPredatesExpectedBehavior() -> Bool {
    if #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) {
        return false
    }

    return true
}

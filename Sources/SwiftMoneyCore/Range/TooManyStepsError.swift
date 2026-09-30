/// Why a set of steps could not be built: there would be more of them than `Int` can count.
///
/// A collection counts its elements with an `Int`. Where `Int` is 64 bits that takes a span of more
/// than 2⁶³ minor units, but on 32-bit watchOS a range of about £21.4 million in 1p steps is already
/// too many. A longer stride gives fewer steps.
public struct TooManyStepsError: Error, Equatable, Hashable, Sendable {
    // Not public: only a steps builder that has counted too many reports one.
    @inlinable
    init() {}
}

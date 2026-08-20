/// The result of scaling a monetary amount by a fraction.
///
/// A monetary amount is always a whole number of the currency's smallest unit, so a fraction that does
/// not divide exactly leaves part of a unit over. The two cases make that difference impossible to
/// overlook.
public enum Scaled<Amount: Equatable> {
    /// The fraction divided exactly.
    case exact(Amount)

    /// Part of the currency's smallest unit was left over.
    ///
    /// The amount is truncated toward zero and `remainder` carries the same sign, so the two together
    /// account for the whole of the result.
    ///
    /// This case cannot be created outside the library, because ``Ratio/FractionalRemainder`` cannot
    /// be. An inexact result therefore always came from a division that really did leave something
    /// over.
    case inexact(
        Amount,
        remainder: Ratio.FractionalRemainder
    )
}

// MARK: - Equatable

extension Scaled: Equatable {}

// MARK: - Sendable

extension Scaled: Sendable where Amount: Sendable {}

// MARK: - Rounding

// Constrained to `Int64` because this is the layer where overflow can still be reported rather than
// trapped, which is what lets `MoneyOf` trap and `Money` throw from the same code.
extension Scaled where Amount == Int64 {
    // The whole number this resolves to under `rule`. `nil` when that is not representable.
    @usableFromInline
    func rounded(_ rule: RoundingRule) -> Int64? {
        switch self {
        case let .exact(whole):
            whole
        case let .inexact(nearZero, remainder):
            remainder.resolving(nearZero, rule)
        }
    }
}


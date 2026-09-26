import Foundation
import SwiftMoneyCore

// `internal` rather than `private`: `majorUnits(of:)` is called from the main FormatStyle file's
// `format(_:)` and from the Attributed split, which needs at least module visibility now that they
// no longer share a file. Still no wider than before the split — never part of the public API.
extension MoneyOf.FormatStyle {
    // The major units to render, after any increment rounding the caller asked for. A step of one
    // is left to fall through, an amount already being a whole count of the smallest units.
    //
    // Rounded here in whole smallest units rather than by ICU, which counts an increment in major
    // units and drops the currency symbol when one is set beside a fraction length. Counting in
    // smallest units is also exact, where a fractional step would not be.
    func majorUnits(of value: MoneyOf<C>) -> Decimal {
        guard let increment = roundingIncrement else {
            return Decimal(majorUnitsOf: value)
        }

        let step = Money.MinorUnits(increment)

        guard step > 1 else {
            return Decimal(majorUnitsOf: value)
        }

        let remainder = value.minorUnits % step

        guard remainder != 0 else {
            return Decimal(majorUnitsOf: value)
        }

        let quotient = value.minorUnits / step

        // Built from the quotient rather than from the amount, so that rounding an amount near
        // the end of the range produces the text it should instead of overflowing. The quotient
        // is at most half the range once the step is two or more, so the carry always fits.
        return Decimal(quotient + carry(remainder: remainder, over: step, from: quotient))
            * exactMajorUnits(step, in: value.currency)
    }

    // Which way the quotient moves: one step away from zero, one step down, or nowhere.
    //
    // The remainder carries the amount's sign, Swift's `%` truncating toward zero, so "away from
    // zero" is the direction the remainder already points in.
    func carry(
        remainder: Money.MinorUnits,
        over step: Money.MinorUnits,
        from quotient: Money.MinorUnits
    ) -> Money.MinorUnits {
        let away: Money.MinorUnits = remainder < 0 ? -1 : 1

        // Doubled in magnitude rather than halving the step, so an odd step still compares
        // exactly, and in unsigned arithmetic so the doubling cannot overflow.
        let doubledRemainder = remainder.magnitude * 2
        let reachesHalfway = doubledRemainder >= step.magnitude
        let passesHalfway = doubledRemainder > step.magnitude

        switch roundingRule {
        case .down:
            return remainder < 0 ? -1 : 0
        case .up:
            return remainder > 0 ? 1 : 0
        case .towardZero:
            return 0
        case .awayFromZero:
            return away
        case .toNearestOrAwayFromZero:
            return reachesHalfway ? away : 0
        case .toNearestOrEven:
            guard reachesHalfway else {
                return 0
            }

            return passesHalfway || !quotient.isMultiple(of: 2) ? away : 0
        @unknown default:
            return reachesHalfway ? away : 0
        }
    }
}

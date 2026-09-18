import Parsing
import SwiftMoneyCore

// CLDR's sample list grammar, from TR35: an `@integer` list then a `@decimal` list, either of which
// may be absent, each a comma separated list of values and `~` ranges that may end in an ellipsis.
//
// Built on access and type erased for the same reason as the condition grammar.
enum PluralSampleGrammar {
    static var sections: AnyParser<Substring, [PluralSample]> {
        Parse {
            spaces
            Optionally { section("@integer") }
            spaces
            Optionally { section("@decimal") }
            spaces
        }
        .map { ($0.0 ?? []) + ($0.1 ?? []) }
        .eraseToAnyParser()
    }

    // A sample value as CLDR writes it. The exponent is the `c6` of `1c6`, a compact way to write a
    // million that no monetary amount uses.
    private struct Value {
        let whole: UInt64
        let fractionDigits: Substring
        let compactExponent: Int?
    }

    private static func section(_ marker: String) -> AnyParser<Substring, [PluralSample]> {
        Parse {
            token(marker)
            requiredSpaces
            list
        }
        .eraseToAnyParser()
    }

    private static var list: AnyParser<Substring, [PluralSample]> {
        Many(1...) {
            entry
        } separator: {
            token(",")
            spaces
        }
        .map { $0.flatMap { $0 } }
        .eraseToAnyParser()
    }

    private static var entry: AnyParser<Substring, [PluralSample]> {
        OneOf {
            ellipsis
            range
            single
        }
        .eraseToAnyParser()
    }

    // CLDR ends a shortened list with an ellipsis, which stands for the values it left out rather
    // than for a value of its own.
    private static var ellipsis: AnyParser<Substring, [PluralSample]> {
        OneOf {
            token("…")
            token("...")
        }
        .map { [PluralSample]() }
        .eraseToAnyParser()
    }

    private static var range: AnyParser<Substring, [PluralSample]> {
        Parse {
            value
            token("~")
            value
        }
        .compactMap { samples(from: $0.0, to: $0.1) }
        .eraseToAnyParser()
    }

    private static var single: AnyParser<Substring, [PluralSample]> {
        value
            .map { sample($0).map { [$0] } ?? [] }
            .eraseToAnyParser()
    }

    private static var value: AnyParser<Substring, Value> {
        Parse {
            UInt64.parser()
            Optionally {
                token(".")
                Prefix<Substring>(1..., while: \.isNumber)
            }
            Optionally {
                OneOf {
                    token("c")
                    token("e")
                }
                Int.parser()
            }
        }
        .map { Value(whole: $0.0, fractionDigits: $0.1 ?? "", compactExponent: $0.2) }
        .eraseToAnyParser()
    }

    // The values from one end of a range to the other, a smallest unit apart, or `nil` when the ends
    // are not written to the same number of fraction digits and so describe no single scale.
    private static func samples(from lower: Value, to upper: Value) -> [PluralSample]? {
        guard lower.fractionDigits.count == upper.fractionDigits.count,
              let low = sample(lower),
              let high = sample(upper),
              low.minorUnits <= high.minorUnits
        else {
            return nil
        }

        return (low.minorUnits ... high.minorUnits).map {
            PluralSample(minorUnits: $0, unitScale: low.unitScale)
        }
    }

    // `nil` when the value cannot be an amount of money: written in compact notation, or beyond the
    // smallest units one amount can hold.
    private static func sample(_ value: Value) -> PluralSample? {
        guard value.compactExponent == nil,
              let scale = UnitScale(decimalPlaces: value.fractionDigits.count),
              let minorUnits = minorUnits(of: value, at: scale)
        else {
            return nil
        }

        return PluralSample(minorUnits: minorUnits, unitScale: scale)
    }

    private static func minorUnits(of value: Value, at scale: UnitScale) -> Int64? {
        let fraction = UInt64(value.fractionDigits) ?? 0
        let (whole, wholeOverflowed) = value.whole.multipliedReportingOverflow(by: UInt64(Int64(scale)))
        let (total, totalOverflowed) = whole.addingReportingOverflow(fraction)

        guard !wholeOverflowed, !totalOverflowed else {
            return nil
        }

        return Int64(exactly: total)
    }

    private static var spaces: AnyParser<Substring, Void> {
        Skip { Prefix<Substring>(while: \.isWhitespace) }.eraseToAnyParser()
    }

    private static var requiredSpaces: AnyParser<Substring, Void> {
        Skip { Prefix<Substring>(1..., while: \.isWhitespace) }.eraseToAnyParser()
    }

    private static func token(_ text: String) -> StartsWith<Substring> {
        StartsWith(text)
    }
}

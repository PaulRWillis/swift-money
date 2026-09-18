import Parsing
import SwiftMoneyLocalization

// CLDR's plural rule condition grammar, from TR35: `or` between groups of `and`ed relations, each
// relation comparing an operand, optionally divided by a modulus, against a list of ranges.
//
// Every parser is built on access and type erased. A parser holds closures, so it cannot be a
// `static let` under strict concurrency, and its own type cannot be written down.
enum PluralConditionGrammar {
    static var condition: AnyParser<Substring, NonEmpty<NonEmpty<PluralRelation>>> {
        Parse {
            spaces
            orOfAndGroups
            spaces
        }
        .eraseToAnyParser()
    }

    // TR35's grammar also has `is`, `in` and `within` relations. CLDR 48's cardinal rules use none of
    // them and the engine does not model them, so they are spotted by name: a locale that ever needs
    // one then fails as unsupported rather than as a syntax error. None of these words can collide
    // with the rest of the grammar, which is operand letters, digits and the `and`/`or` joiners.
    static func unmodelledRelation(in condition: String) -> String? {
        condition
            .split(whereSeparator: \.isWhitespace)
            .first { unmodelledRelations.contains($0) }
            .map(String.init)
    }

    private static let unmodelledRelations: Set<Substring> = ["is", "in", "not", "within"]

    private static var orOfAndGroups: AnyParser<Substring, NonEmpty<NonEmpty<PluralRelation>>> {
        Many(1...) {
            andGroup
        } separator: {
            requiredSpaces
            token("or")
            requiredSpaces
        }
        .compactMap(NonEmpty.init)
        .eraseToAnyParser()
    }

    private static var andGroup: AnyParser<Substring, NonEmpty<PluralRelation>> {
        Many(1...) {
            relation
        } separator: {
            requiredSpaces
            token("and")
            requiredSpaces
        }
        .compactMap(NonEmpty.init)
        .eraseToAnyParser()
    }

    private static var relation: AnyParser<Substring, PluralRelation> {
        Parse {
            PluralOperand.parser(of: Substring.self)
            Optionally { modulus }
            spaces
            comparison
        }
        .map { PluralRelation(operand: $0.0, modulus: $0.1, comparison: $0.2) }
        .eraseToAnyParser()
    }

    private static var modulus: AnyParser<Substring, PluralModulus> {
        Parse {
            spaces
            OneOf {
                token("%")
                token("mod")
            }
            spaces
            Int.parser()
        }
        .compactMap(PluralModulus.init(exactly:))
        .eraseToAnyParser()
    }

    private static var comparison: AnyParser<Substring, PluralRelation.Comparison> {
        Parse {
            OneOf {
                token("!=").map { PluralRelation.Comparison.notEquals }
                token("=").map { PluralRelation.Comparison.equals }
            }
            spaces
            rangeList
        }
        .map { $0.0($0.1) }
        .eraseToAnyParser()
    }

    private static var rangeList: AnyParser<Substring, NonEmpty<PluralRange>> {
        Many(1...) {
            range
        } separator: {
            token(",")
            spaces
        }
        .compactMap(NonEmpty.init)
        .eraseToAnyParser()
    }

    private static var range: AnyParser<Substring, PluralRange> {
        Parse {
            UInt64.parser()
            Optionally {
                token("..")
                UInt64.parser()
            }
        }
        .compactMap { bounds in
            guard let upperBound = bounds.1 else {
                return PluralRange(bounds.0)
            }

            return PluralRange(lowerBound: bounds.0, upperBound: upperBound)
        }
        .eraseToAnyParser()
    }

    // The input type is spelled out because the parser builder cannot infer one from a whitespace
    // parser alone, and a condition can lead with whitespace.
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

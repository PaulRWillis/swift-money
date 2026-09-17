import Foundation
import SwiftMoneyCore
import SwiftMoneyFoundation

extension FormatMatrix {
    /// One (currency, locale, option combination, amount) cell where the engine's rendering and the
    /// platform's ICU rendering disagree.
    package struct Deviation: Equatable {
        package let localeID: String
        package let currencyCode: String
        package let combinationID: String
        package let amount: Int64
        package let engine: String
        package let icu: String

        // Explicit: the synthesized memberwise initializer is `internal` regardless of the type's
        // or its properties' own access level, and tests construct a `Deviation` from outside this
        // module to compare against.
        package init(
            localeID: String, currencyCode: String, combinationID: String,
            amount: Int64, engine: String, icu: String
        ) {
            self.localeID = localeID
            self.currencyCode = currencyCode
            self.combinationID = combinationID
            self.amount = amount
            self.engine = engine
            self.icu = icu
        }
    }

    /// The amount, rendered by the platform's ICU through the same style the engine would use for it.
    ///
    /// Built from the same builder chain as ``engineFormatted(_:localeID:combination:)``, so the two
    /// sides differ only in whether `decimalStyle(for:)` or the engine renders the result.
    package static func icuFormatted(_ money: Money, localeID: String, combination: Combination) -> String {
        let style = Money.FormatStyle().locale(Locale(identifier: localeID))
            .presentation(combination.presentation).sign(strategy: combination.sign)
            .grouping(combination.grouping).decimalSeparator(strategy: combination.separator)
        return style.decimalStyle(for: money.currency).format(Decimal(majorUnitsOf: money))
    }

    /// The amount, rendered by the Foundation-free engine.
    package static func engineFormatted(_ money: Money, localeID: String, combination: Combination) -> String {
        Money.FormatStyle().locale(Locale(identifier: localeID))
            .presentation(combination.presentation).sign(strategy: combination.sign)
            .grouping(combination.grouping).decimalSeparator(strategy: combination.separator)
            .format(money)
    }

    // The comparison core, generic over how a cell is rendered, so the predicate and cardinality can
    // be pinned with fixture renderers instead of calling real ICU for every test run.
    package static func deviations(
        currencies: [Currency],
        localeIDs: [String],
        combinations: [Combination],
        amounts: [Int64],
        engine: (Currency, String, Combination, Int64) -> String,
        icu: (Currency, String, Combination, Int64) -> String
    ) -> [Deviation] {
        var found: [Deviation] = []
        for currency in currencies {
            for localeID in localeIDs {
                for combination in combinations {
                    for amount in amounts {
                        let engineOutput = engine(currency, localeID, combination, amount)
                        let icuOutput = icu(currency, localeID, combination, amount)
                        guard engineOutput != icuOutput else {
                            continue
                        }

                        found.append(Deviation(
                            localeID: localeID, currencyCode: String(currency.code),
                            combinationID: combination.id, amount: amount,
                            engine: engineOutput, icu: icuOutput
                        ))
                    }
                }
            }
        }
        return found
    }

    /// Every (currency, locale, combination, amount) cell where the Foundation-free engine and the
    /// platform's ICU disagree, rendered through the exact style each side would really use.
    package static func deviations(
        currencies: [Currency],
        localeIDs: [String],
        combinations: [Combination],
        amounts: [Int64]
    ) -> [Deviation] {
        deviations(
            currencies: currencies, localeIDs: localeIDs, combinations: combinations, amounts: amounts,
            engine: { currency, localeID, combination, amount in
                engineFormatted(Money(minorUnits: amount, currency: currency), localeID: localeID, combination: combination)
            },
            icu: { currency, localeID, combination, amount in
                icuFormatted(Money(minorUnits: amount, currency: currency), localeID: localeID, combination: combination)
            }
        )
    }
}

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

        /// Whether this cell already matches the known Foundation defect, not new engine-vs-ICU
        /// information.
        package let isKnownFoundationGroupingDefect: Bool

        // Explicit: the synthesized memberwise init would be `internal`, and tests construct a
        // `Deviation` from outside this module.
        package init(
            localeID: String, currencyCode: String, combinationID: String, amount: Int64,
            engine: String, icu: String, isKnownFoundationGroupingDefect: Bool
        ) {
            self.localeID = localeID
            self.currencyCode = currencyCode
            self.combinationID = combinationID
            self.amount = amount
            self.engine = engine
            self.icu = icu
            self.isKnownFoundationGroupingDefect = isKnownFoundationGroupingDefect
        }

        /// The cell and both renderings on one line, naming the locale first so a sorted report
        /// groups by locale and two reports can be compared line by line.
        package var reportLine: String {
            "\(localeID) \(currencyCode) \(combinationID) \(amount): engine '\(engine)' vs ICU '\(icu)'"
        }

        /// The presentation this cell used, which leads its combination's id.
        package var presentationName: String {
            String(combinationID.prefix { $0 != "|" })
        }
    }

    /// One line per locale, currency and presentation that disagrees with ICU: how many cells differ
    /// and one of them.
    ///
    /// A currency renamed between CLDR releases differs in every cell that names it, which runs to
    /// hundreds of lines saying the same thing. Grouped, each cause reads once.
    package static func summaryLines(for deviations: [Deviation]) -> [String] {
        var byCause: [String: (example: Deviation, count: Int)] = [:]

        // Sorted first, so the example for a cause is the same whatever order the cells arrived in.
        for deviation in deviations.sorted(by: { $0.reportLine < $1.reportLine }) {
            let cause = "\(deviation.localeID) \(deviation.currencyCode) \(deviation.presentationName)"
            let found = byCause[cause]
            byCause[cause] = (found?.example ?? deviation, (found?.count ?? 0) + 1)
        }

        return byCause
            .map { cause, found in
                "\(cause): \(found.count) cell(s), e.g. engine '\(found.example.engine)' vs ICU '\(found.example.icu)'"
            }
            .sorted()
    }

    /// The amount, rendered by the platform's ICU, using the same options the engine would.
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

    /// The comparison core. Generic over how a cell is rendered, so tests can pin the predicate and
    /// cardinality with fixture renderers instead of calling real ICU.
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
                    // A cell the data cannot render is rendered by ICU on both sides, so comparing it
                    // would report agreement the engine had no part in.
                    guard isEngineCovered(currency, localeID: localeID, presentation: combination.presentation) else {
                        continue
                    }

                    for amount in amounts {
                        let engineOutput = engine(currency, localeID, combination, amount)
                        let icuOutput = icu(currency, localeID, combination, amount)
                        guard engineOutput != icuOutput else {
                            continue
                        }

                        found.append(Deviation(
                            localeID: localeID, currencyCode: String(currency.code),
                            combinationID: combination.id, amount: amount,
                            engine: engineOutput, icu: icuOutput,
                            isKnownFoundationGroupingDefect: combination.isKnownFoundationGroupingDefect
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

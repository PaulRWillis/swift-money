import SwiftMoneyCore
import SwiftMoneyLocalization
import Testing

/// Returns the code the tables file a currency under, parsed from text as the generator parses it.
///
/// ```swift
/// try tableCode("GBP").value   // 28816
/// try tableCode("USDT")        // fails the test
/// ```
///
/// - Parameters:
///   - text: The currency code, as CLDR spells it.
///   - sourceLocation: Where a failure is reported.
/// - Returns: The code the tables file `text` under.
/// - Throws: The error `#require` throws if `text` isn't a currency code, or if the tables can't
///   hold it.
func tableCode(
    _ text: String, sourceLocation: SourceLocation = #_sourceLocation
) throws -> Localization.CurrencyCode {
    let currencyCode = try #require(CurrencyCode(string: text), sourceLocation: sourceLocation)
    return try #require(Localization.CurrencyCode(currencyCode), sourceLocation: sourceLocation)
}

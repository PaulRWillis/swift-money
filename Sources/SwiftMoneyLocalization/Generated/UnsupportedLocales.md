# Locales without built-in currency formatting

Generated from CLDR 48.2.0 by GenerateSwiftMoneyLocalization. Do not edit by hand.
Regenerate with: (cd Tools/cldr && npm ci) && swift run GenerateSwiftMoneyLocalization

The engine formats 8 of the 10 CLDR locales this build reads. The 2 below are left out, each because it writes something the packed tables have no shape for. They keep the ICU fallback, and rejoin the list on their own once that shape exists.

## arranges a negative amount in its standard pattern (1)
- nl: \u{A4}\u{A0}#,##0.00;\u{A4}\u{A0}-#,##0.00

## writes amounts in digits other than 0 to 9 (1)
- ar-EG: arab

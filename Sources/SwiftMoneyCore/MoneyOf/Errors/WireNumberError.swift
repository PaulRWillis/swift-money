// Codable relies on `any Encoder`/`any Decoder`, metatypes, and `EncodingError`/`DecodingError`, none of
// which Embedded Swift compiles. It is excluded there; everything else in the core is Embedded-clean.
#if !hasFeature(Embedded)

// Why a JSON number is not an amount.
enum WireNumberError: Error {
    // A fraction arrived where a whole number of the smallest units was expected.
    case fractionalMinorUnits(Currency, value: Double)

    // The digits are not a whole number of the smallest units of the currency they are in.
    case inexactAmount(Currency, text: String)

    // Past where a `Double` can tell one amount from the next.
    case beyondExactRange(Currency, text: String)
}

#endif

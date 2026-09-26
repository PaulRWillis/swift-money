/// Why `MoneyCodingFormat.fields(currencyKey:amountKey:)` refused a set of keys.
public enum MoneyCodingFormatError: Error, Equatable, Sendable {
    /// Two of this shape's keys are the same string, so writing one would silently overwrite the
    /// other — `currencyKey`, `amountKey`, or the reserved `"scale"` key a custom currency may
    /// also need.
    case duplicateFieldKey(String)
}

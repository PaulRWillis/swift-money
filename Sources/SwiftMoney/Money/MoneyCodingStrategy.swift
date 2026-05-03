#if canImport(Foundation)
import Foundation

// MARK: - MoneyAmountEncodingStrategy

/// Controls how the `amount` field is encoded inside a
/// ``MoneyEncodingStrategy/object(amount:)`` keyed container.
///
/// | Case | JSON for £1.25 |
/// |------|----------------|
/// | ``minorUnits`` | `125` |
/// | ``majorUnits`` | `1.25` |
/// | ``string(locale:)`` with `en_GB` | `"£1.25"` |
///
/// Each case must match the ``MoneyAmountDecodingStrategy`` used on the receiving end.
public enum MoneyAmountEncodingStrategy: Sendable {

    /// Encode as an integer number of minor units.
    ///
    /// For example, £1.25 encodes as `125` (in pence).
    ///
    /// This is the only strategy that preserves the ``Money/nan`` sentinel (`Int64.min`).
    case minorUnits

    /// Encode as a decimal major-unit value.
    ///
    /// For example, £1.25 encodes as the JSON number `1.25`.
    ///
    /// - Note: Encoding is exact (pure base-10 arithmetic). Decoding rounds to the
    ///   nearest minor unit, correcting any floating-point representation artefacts
    ///   present in older JSON parsers. For bit-perfect fidelity, prefer
    ///   ``minorUnits`` or ``string(locale:)``.
    ///
    /// - Important: ``Money/nan`` cannot be represented as a major-unit decimal and
    ///   will throw `EncodingError.invalidValue` at encode time.
    case majorUnits

    /// Encode as a formatted currency string using the given locale.
    ///
    /// For example, £1.25 encodes as `"£1.25"` with the `en_GB` locale.
    ///
    /// - Important: ``Money/nan`` cannot be represented as a string and will throw
    ///   `EncodingError.invalidValue` at encode time.
    case string(locale: Locale)
}

extension MoneyAmountEncodingStrategy {

    /// Encode as a formatted currency string using ``Locale/autoupdatingCurrent``.
    public static var string: Self { .string(locale: .autoupdatingCurrent) }
}

// MARK: - MoneyEncodingStrategy

/// Controls how a `Money<C>` value is encoded.
///
/// Configure the strategy via ``JSONEncoder/moneyEncodingStrategy`` (preferred) or by
/// setting `encoder.userInfo[.moneyEncodingStrategy]` directly.
///
/// All variants shown for `Money<GBP>(minorUnits: 125)` (= £1.25):
///
/// ```swift
/// var encoder = JSONEncoder()
///
/// // ── .object ─────────────────────────────────────────────────────────────
/// // Keyed container with "currencyCode" and "amount". Default strategy.
///
/// encoder.moneyEncodingStrategy = .object
/// // {"currencyCode":"GBP","amount":1.25}
///
/// encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
/// // {"currencyCode":"GBP","amount":1.25}
///
/// encoder.moneyEncodingStrategy = .object(amount: .minorUnits)
/// // {"currencyCode":"GBP","amount":125}
///
/// encoder.moneyEncodingStrategy = .object(
///     amount: .string(locale: Locale(identifier: "en_GB")))
/// // {"currencyCode":"GBP","amount":"£1.25"}
///
/// // ── Bare values (no currency code in the output) ─────────────────────────
///
/// encoder.moneyEncodingStrategy = .majorUnits
/// // 1.25
///
/// encoder.moneyEncodingStrategy = .minorUnits  // also preserves Money.nan
/// // 125
///
/// encoder.moneyEncodingStrategy = .string(locale: Locale(identifier: "en_GB"))
/// // "£1.25"
///
/// encoder.moneyEncodingStrategy = .string  // uses Locale.autoupdatingCurrent
/// // "£1.25"  (locale-dependent)
/// ```
///
/// - Important: Only ``minorUnits`` preserves ``Money/nan``; all other strategies throw
///   `EncodingError.invalidValue` when encoding a NaN value.
public enum MoneyEncodingStrategy: Sendable {

    /// Encode as a JSON object with separate `"currencyCode"` and `"amount"` fields.
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    ///
    /// The `amount` sub-field uses the given ``MoneyAmountEncodingStrategy``.
    ///
    /// - Important: ``Money/nan`` cannot be represented and will throw
    ///   `EncodingError.invalidValue` at encode time.
    case object(amount: MoneyAmountEncodingStrategy)

    /// Encode as a bare integer number of minor units.
    ///
    /// ```json
    /// 125
    /// ```
    ///
    /// This is the only strategy that preserves the ``Money/nan`` sentinel.
    case minorUnits

    /// Encode as a bare decimal major-unit value.
    ///
    /// ```json
    /// 1.25
    /// ```
    ///
    /// - Note: Encoding is exact. See ``MoneyAmountEncodingStrategy/majorUnits``
    ///   for precision notes.
    /// - Important: ``Money/nan`` cannot be represented and will throw
    ///   `EncodingError.invalidValue` at encode time.
    case majorUnits

    /// Encode as a formatted currency string using the given locale.
    ///
    /// ```json
    /// "£1.25"
    /// ```
    ///
    /// - Important: ``Money/nan`` cannot be represented and will throw
    ///   `EncodingError.invalidValue` at encode time.
    case string(locale: Locale)
}

extension MoneyEncodingStrategy {

    /// Encode as a JSON object with `amount` as a decimal major-unit value.
    ///
    /// Equivalent to `.object(amount: .majorUnits)`. This is the **default** strategy.
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    public static var object: Self { .object(amount: .majorUnits) }

    /// Encode as a formatted currency string using ``Locale/autoupdatingCurrent``.
    public static var string: Self { .string(locale: .autoupdatingCurrent) }
}

// MARK: - MoneyAmountDecodingStrategy

/// Controls how the `amount` field is decoded inside a
/// ``MoneyDecodingStrategy/object(amount:)`` keyed container.
///
/// | Case | Expected JSON for £1.25 |
/// |------|--------------------------|
/// | ``minorUnits`` | `125` |
/// | ``majorUnits`` | `1.25` |
/// | ``string(locale:)`` with `en_GB` | `"£1.25"` |
///
/// Each case must match the ``MoneyAmountEncodingStrategy`` that produced the data.
public enum MoneyAmountDecodingStrategy: Sendable {

    /// Decode from an integer number of minor units.
    ///
    /// Expects a JSON integer. For example, `125` decodes to £1.25.
    ///
    /// `Int64.min` (the ``Money/nan`` sentinel) is preserved on decode.
    case minorUnits

    /// Decode from a decimal major-unit value.
    ///
    /// Expects a JSON number or numeric string. The value is multiplied by the
    /// currency's ``Currency/minimalQuantisation`` and rounded to the nearest minor
    /// unit using `.plain` rounding.
    ///
    /// - Note: On Apple platforms (macOS 15+, iOS 18+) `JSONDecoder` decodes JSON
    ///   numbers as `Decimal` directly, avoiding the historical Double-intermediate
    ///   precision loss (SR-7054). The rounding step provides an additional safety
    ///   net for older platforms.
    case majorUnits

    /// Decode from a formatted currency string using the given locale.
    ///
    /// Expects a JSON string in the format produced by
    /// ``MoneyAmountEncodingStrategy/string(locale:)``.
    case string(locale: Locale)
}

extension MoneyAmountDecodingStrategy {

    /// Decode from a formatted currency string using ``Locale/autoupdatingCurrent``.
    public static var string: Self { .string(locale: .autoupdatingCurrent) }
}

// MARK: - MoneyDecodingStrategy

/// Controls how a `Money<C>` value is decoded.
///
/// Configure the strategy via ``JSONDecoder/moneyDecodingStrategy`` (preferred) or by
/// setting `decoder.userInfo[.moneyDecodingStrategy]` directly.
///
/// The strategy **must** match the ``MoneyEncodingStrategy`` that produced the data.
/// All variants shown decoding `Money<GBP>(minorUnits: 125)` (= £1.25):
///
/// ```swift
/// var decoder = JSONDecoder()
///
/// // ── .object ─────────────────────────────────────────────────────────────
/// // Expects a keyed container with "currencyCode" and "amount".
/// // "currencyCode" must match Currency.code or DecodingError is thrown.
///
/// decoder.moneyDecodingStrategy = .object
/// // {"currencyCode":"GBP","amount":1.25}  →  Money<GBP>(minorUnits: 125)
///
/// decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
/// // {"currencyCode":"GBP","amount":1.25}  →  Money<GBP>(minorUnits: 125)
///
/// decoder.moneyDecodingStrategy = .object(amount: .minorUnits)
/// // {"currencyCode":"GBP","amount":125}   →  Money<GBP>(minorUnits: 125)
///
/// decoder.moneyDecodingStrategy = .object(
///     amount: .string(locale: Locale(identifier: "en_GB")))
/// // {"currencyCode":"GBP","amount":"£1.25"}  →  Money<GBP>(minorUnits: 125)
///
/// // ── Bare values (no currency code in the JSON) ───────────────────────────
///
/// decoder.moneyDecodingStrategy = .majorUnits
/// // 1.25  →  Money<GBP>(minorUnits: 125)
///
/// decoder.moneyDecodingStrategy = .minorUnits  // also preserves Money.nan
/// // 125   →  Money<GBP>(minorUnits: 125)
///
/// decoder.moneyDecodingStrategy = .string(locale: Locale(identifier: "en_GB"))
/// // "£1.25"  →  Money<GBP>(minorUnits: 125)
///
/// decoder.moneyDecodingStrategy = .string  // uses Locale.autoupdatingCurrent
/// // "£1.25"  →  Money<GBP>(minorUnits: 125)  (locale-dependent)
/// ```
///
/// - Note: For `.object`, `"currencyCode"` must equal `Currency.code`; a mismatch throws
///   `DecodingError.typeMismatch`. Only ``minorUnits`` preserves ``Money/nan``.
public enum MoneyDecodingStrategy: Sendable {

    /// Decode from a JSON object with separate `"currencyCode"` and `"amount"` fields.
    ///
    /// The `"currencyCode"` value must match the target `Currency.code`; a mismatch
    /// throws ``DecodingError/typeMismatch(_:_:)``.
    ///
    /// The `amount` sub-field uses the given ``MoneyAmountDecodingStrategy``.
    case object(amount: MoneyAmountDecodingStrategy)

    /// Decode from a bare integer number of minor units.
    ///
    /// `Int64.min` (the ``Money/nan`` sentinel) is preserved on decode.
    case minorUnits

    /// Decode from a bare decimal major-unit value.
    ///
    /// See ``MoneyAmountDecodingStrategy/majorUnits`` for precision notes.
    case majorUnits

    /// Decode from a formatted currency string using the given locale.
    case string(locale: Locale)
}

extension MoneyDecodingStrategy {

    /// Decode from a JSON object with `amount` as a decimal major-unit value.
    ///
    /// Equivalent to `.object(amount: .majorUnits)`. This is the **default** strategy.
    public static var object: Self { .object(amount: .majorUnits) }

    /// Decode from a formatted currency string using ``Locale/autoupdatingCurrent``.
    public static var string: Self { .string(locale: .autoupdatingCurrent) }
}

// MARK: - CodingUserInfoKey constants

extension CodingUserInfoKey {

    /// The user-info key for ``MoneyEncodingStrategy``.
    ///
    /// Set this key on `encoder.userInfo` to configure how `Money` values are encoded.
    /// Prefer the ``JSONEncoder/moneyEncodingStrategy`` convenience property.
    public static let moneyEncodingStrategy: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "io.swiftmoney.encoding-strategy") else {
            preconditionFailure("CodingUserInfoKey initialisation failed for a non-empty raw value.")
        }
        return key
    }()

    /// The user-info key for ``MoneyDecodingStrategy``.
    ///
    /// Set this key on `decoder.userInfo` to configure how `Money` values are decoded.
    /// Prefer the ``JSONDecoder/moneyDecodingStrategy`` convenience property.
    public static let moneyDecodingStrategy: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "io.swiftmoney.decoding-strategy") else {
            preconditionFailure("CodingUserInfoKey initialisation failed for a non-empty raw value.")
        }
        return key
    }()
}

// MARK: - JSONEncoder / JSONDecoder convenience properties

extension JSONEncoder {

    /// The strategy used to encode `Money` values.
    ///
    /// Defaults to ``MoneyEncodingStrategy/object`` when not set.
    ///
    /// All strategies for `Money<GBP>(minorUnits: 125)` (= £1.25):
    ///
    /// ```swift
    /// var encoder = JSONEncoder()
    ///
    /// encoder.moneyEncodingStrategy = .object
    /// // {"currencyCode":"GBP","amount":1.25}   ← default
    ///
    /// encoder.moneyEncodingStrategy = .object(amount: .majorUnits)
    /// // {"currencyCode":"GBP","amount":1.25}
    ///
    /// encoder.moneyEncodingStrategy = .object(amount: .minorUnits)
    /// // {"currencyCode":"GBP","amount":125}
    ///
    /// encoder.moneyEncodingStrategy = .object(
    ///     amount: .string(locale: Locale(identifier: "en_GB")))
    /// // {"currencyCode":"GBP","amount":"£1.25"}
    ///
    /// encoder.moneyEncodingStrategy = .majorUnits
    /// // 1.25
    ///
    /// encoder.moneyEncodingStrategy = .minorUnits  // also preserves Money.nan
    /// // 125
    ///
    /// encoder.moneyEncodingStrategy = .string(locale: Locale(identifier: "en_GB"))
    /// // "£1.25"
    ///
    /// encoder.moneyEncodingStrategy = .string  // uses Locale.autoupdatingCurrent
    /// // "£1.25"  (locale-dependent)
    /// ```
    ///
    /// - Note: Only `.minorUnits` preserves ``Money/nan``; all other strategies throw
    ///   `EncodingError.invalidValue` when encoding a NaN value.
    public var moneyEncodingStrategy: MoneyEncodingStrategy {
        get { userInfo[.moneyEncodingStrategy] as? MoneyEncodingStrategy ?? .object }
        set { userInfo[.moneyEncodingStrategy] = newValue }
    }
}

extension JSONDecoder {

    /// The strategy used to decode `Money` values.
    ///
    /// Defaults to ``MoneyDecodingStrategy/object`` when not set.
    /// The strategy **must** match the ``MoneyEncodingStrategy`` that produced the data.
    ///
    /// All strategies for `Money<GBP>(minorUnits: 125)` (= £1.25):
    ///
    /// ```swift
    /// var decoder = JSONDecoder()
    ///
    /// decoder.moneyDecodingStrategy = .object
    /// // {"currencyCode":"GBP","amount":1.25}   ← default
    ///
    /// decoder.moneyDecodingStrategy = .object(amount: .majorUnits)
    /// // {"currencyCode":"GBP","amount":1.25}
    ///
    /// decoder.moneyDecodingStrategy = .object(amount: .minorUnits)
    /// // {"currencyCode":"GBP","amount":125}
    ///
    /// decoder.moneyDecodingStrategy = .object(
    ///     amount: .string(locale: Locale(identifier: "en_GB")))
    /// // {"currencyCode":"GBP","amount":"£1.25"}
    ///
    /// decoder.moneyDecodingStrategy = .majorUnits
    /// // 1.25
    ///
    /// decoder.moneyDecodingStrategy = .minorUnits  // also preserves Money.nan
    /// // 125
    ///
    /// decoder.moneyDecodingStrategy = .string(locale: Locale(identifier: "en_GB"))
    /// // "£1.25"
    ///
    /// decoder.moneyDecodingStrategy = .string  // uses Locale.autoupdatingCurrent
    /// // "£1.25"  (locale-dependent)
    /// ```
    ///
    /// - Note: For `.object`, `"currencyCode"` must equal `Currency.code`; a mismatch throws
    ///   `DecodingError.typeMismatch`. Only `.minorUnits` preserves ``Money/nan``.
    public var moneyDecodingStrategy: MoneyDecodingStrategy {
        get { userInfo[.moneyDecodingStrategy] as? MoneyDecodingStrategy ?? .object }
        set { userInfo[.moneyDecodingStrategy] = newValue }
    }
}
#endif

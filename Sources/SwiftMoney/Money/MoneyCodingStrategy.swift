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
///
/// Each case must match the ``MoneyAmountDecodingStrategy`` used on the receiving end.
public enum MoneyAmountEncodingStrategy: Sendable {

    /// Encode as an integer number of minor units.
    ///
    /// For example, £1.25 encodes as `125` (in pence).
    case minorUnits

    /// Encode as a decimal major-unit value.
    ///
    /// For example, £1.25 encodes as the JSON number `1.25`.
    ///
    /// - Note: Encoding is exact (pure base-10 arithmetic). Decoding rounds to the
    ///   nearest minor unit, correcting any floating-point representation artefacts
    ///   present in older JSON parsers. For bit-perfect fidelity, prefer
    ///   ``minorUnits``.
    case majorUnits
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
/// // ── Bare values (no currency code in the output) ─────────────────────────
///
/// encoder.moneyEncodingStrategy = .majorUnits
/// // 1.25
///
/// encoder.moneyEncodingStrategy = .minorUnits
/// // 125
/// ```
public enum MoneyEncodingStrategy: Sendable {

    /// Encode as a JSON object with separate `"currencyCode"` and `"amount"` fields.
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    ///
    /// The `amount` sub-field uses the given ``MoneyAmountEncodingStrategy``.
    case object(_ amount: MoneyAmountEncodingStrategy)

    /// Encode as a bare integer number of minor units.
    ///
    /// ```json
    /// 125
    /// ```
    case minorUnits

    /// Encode as a bare decimal major-unit value.
    ///
    /// ```json
    /// 1.25
    /// ```
    ///
    /// - Note: Encoding is exact. See ``MoneyAmountEncodingStrategy/majorUnits``
    ///   for precision notes.
    case majorUnits
}

extension MoneyEncodingStrategy {

    /// Encode as a JSON object with `amount` as a decimal major-unit value.
    ///
    /// Equivalent to `.object(amount: .majorUnits)`. This is the **default** strategy.
    ///
    /// ```json
    /// {"currencyCode":"GBP","amount":1.25}
    /// ```
    public static var object: Self { .object(.majorUnits) }
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

    #warning("Should we not also have a JSON object decoder?")

    /// Decode from an integer number of minor units.
    ///
    /// Expects a JSON integer. For example, `125` decodes to £1.25.
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
/// decoder.moneyDecodingStrategy = .minorUnits
/// // 125   →  Money<GBP>(minorUnits: 125)
/// ```
///
/// - Note: For `.object`, `"currencyCode"` must equal `Currency.code`; a mismatch throws
///   `DecodingError.typeMismatch`.
public enum MoneyDecodingStrategy: Sendable {

    /// Decode from a JSON object with separate `"currencyCode"` and `"amount"` fields.
    ///
    /// The `"currencyCode"` value must match the target `Currency.code`; a mismatch
    /// throws ``DecodingError/typeMismatch(_:_:)``.
    ///
    /// The `amount` sub-field uses the given ``MoneyAmountDecodingStrategy``.
    case object(_ amount: MoneyAmountDecodingStrategy)

    /// Decode from a bare integer number of minor units.
    case minorUnits

    /// Decode from a bare decimal major-unit value.
    ///
    /// See ``MoneyAmountDecodingStrategy/majorUnits`` for precision notes.
    case majorUnits
}

extension MoneyDecodingStrategy {

    /// Decode from a JSON object with `amount` as a decimal major-unit value.
    ///
    /// Equivalent to `.object(amount: .majorUnits)`. This is the **default** strategy.
    public static var object: Self { .object(.majorUnits) }
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
    /// encoder.moneyEncodingStrategy = .majorUnits
    /// // 1.25
    ///
    /// encoder.moneyEncodingStrategy = .minorUnits
    /// // 125
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
    /// decoder.moneyDecodingStrategy = .majorUnits
    /// // 1.25
    ///
    /// decoder.moneyDecodingStrategy = .minorUnits
    /// // 125
    /// ```
    ///
    /// - Note: For `.object`, `"currencyCode"` must equal `Currency.code`; a mismatch throws
    ///   `DecodingError.typeMismatch`.
    public var moneyDecodingStrategy: MoneyDecodingStrategy {
        get { userInfo[.moneyDecodingStrategy] as? MoneyDecodingStrategy ?? .object }
        set { userInfo[.moneyDecodingStrategy] = newValue }
    }
}
#endif

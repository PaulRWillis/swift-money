#if canImport(Foundation)
import Foundation

// MARK: - MoneyBagEncodingStrategy

/// Controls how a ``MoneyBag`` is encoded.
///
/// Configure the strategy via ``JSONEncoder/moneyBagEncodingStrategy`` (preferred) or by
/// setting `encoder.userInfo[.moneyBagEncodingStrategy]` directly.
///
/// All variants for a bag containing £1.25 (GBP, minQ=100) and ¥500 (JPY, minQ=1):
///
/// ```swift
/// var encoder = JSONEncoder()
///
/// // ── .full ─────────────────────────────────────────────────────────────────
/// // Default. Wrapped entries array; each entry is self-contained.
/// encoder.moneyBagEncodingStrategy = .full
/// // {"entries":[
/// //   {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125},
/// //   {"currencyCode":"JPY","minimalQuantisation":1,"minorUnits":500}
/// // ]}
///
/// // ── .array ────────────────────────────────────────────────────────────────
/// // Bare JSON array, no wrapper key. Per-entry format is configurable.
/// encoder.moneyBagEncodingStrategy = .array(entry: .full)
/// // [
/// //   {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125},
/// //   {"currencyCode":"JPY","minimalQuantisation":1,"minorUnits":500}
/// // ]
///
/// encoder.moneyBagEncodingStrategy = .array(entry: .object(amount: .majorUnits))
/// // [
/// //   {"currencyCode":"GBP","amount":1.25},
/// //   {"currencyCode":"JPY","amount":500}
/// // ]
///
/// // ── .dictionary ───────────────────────────────────────────────────────────
/// // Compact object keyed by currency code. Very common in banking/budgeting APIs.
/// encoder.moneyBagEncodingStrategy = .dictionary(amount: .majorUnits)
/// // {"GBP":1.25,"JPY":500}
///
/// encoder.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)
/// // {"GBP":125,"JPY":500}
/// ```
///
/// - Important: `.array` and `.dictionary` strategies that use a non-`.minorUnits` amount
///   encoding throw `EncodingError.invalidValue` for NaN entries.
public enum MoneyBagEncodingStrategy: Sendable {

    /// Encode as `{"entries":[...]}` where each entry uses ``AnyMoneyEncodingStrategy/full``.
    ///
    /// This is the **default** strategy. It is fully self-contained and preserves NaN entries.
    case full

    /// Encode as a bare JSON array where each element uses the given ``AnyMoneyEncodingStrategy``.
    ///
    /// Common for REST APIs that expect a flat array of currency objects.
    case array(entry: AnyMoneyEncodingStrategy)

    /// Encode as a JSON object keyed by currency code, with amounts encoded using the given
    /// ``MoneyAmountEncodingStrategy``.
    ///
    /// Keys are sorted alphabetically for deterministic output.
    case dictionary(amount: MoneyAmountEncodingStrategy)
}

extension MoneyBagEncodingStrategy {

    /// Encode as a bare array with each entry in ``AnyMoneyEncodingStrategy/full`` format.
    ///
    /// Equivalent to `.array(entry: .full)`.
    public static var array: Self { .array(entry: .full) }

    /// Encode as a currency-keyed dictionary with decimal major-unit amounts.
    ///
    /// Equivalent to `.dictionary(amount: .majorUnits)`.
    public static var dictionary: Self { .dictionary(amount: .majorUnits) }
}

// MARK: - MoneyBagDecodingStrategy

/// Controls how a ``MoneyBag`` is decoded.
///
/// Configure the strategy via ``JSONDecoder/moneyBagDecodingStrategy`` (preferred) or by
/// setting `decoder.userInfo[.moneyBagDecodingStrategy]` directly.
///
/// The strategy **must** match the ``MoneyBagEncodingStrategy`` that produced the data.
///
/// All variants (decoding a bag with GBP and JPY entries):
///
/// ```swift
/// var decoder = JSONDecoder()
///
/// // ── .full ─────────────────────────────────────────────────────────────────
/// decoder.moneyBagDecodingStrategy = .full
/// // {"entries":[...full AnyMoney objects...]}   ← default
///
/// // ── .array ────────────────────────────────────────────────────────────────
/// decoder.moneyBagDecodingStrategy = .array(entry: .full)
/// // [...full AnyMoney objects...]
///
/// decoder.moneyBagDecodingStrategy = .array(
///     entry: .object(amount: .majorUnits, resolver: registry.asResolver()))
/// // [{"currencyCode":"GBP","amount":1.25},...]
///
/// // ── .dictionary ───────────────────────────────────────────────────────────
/// decoder.moneyBagDecodingStrategy = .dictionary(
///     amount: .majorUnits,
///     resolver: registry.asResolver())
/// // {"GBP":1.25,"JPY":500}
///
/// decoder.moneyBagDecodingStrategy = .dictionary(
///     amount: .minorUnits,
///     resolver: registry.asResolver())
/// // {"GBP":125,"JPY":500}
/// ```
///
/// - Note: For `.array(entry: .object(...))` and `.dictionary`, a `resolver` closure is
///   required to map currency codes to ``MinimalQuantisation``. Use ``CurrencyRegistry``
///   to build a resolver without a hand-coded switch statement.
public enum MoneyBagDecodingStrategy: Sendable {

    /// Decode from `{"entries":[...]}` where each entry is a full ``AnyMoney`` object.
    ///
    /// This is the **default** strategy.
    case full

    /// Decode from a bare JSON array where each element uses the given ``AnyMoneyDecodingStrategy``.
    case array(entry: AnyMoneyDecodingStrategy)

    /// Decode from a JSON object keyed by currency code.
    ///
    /// The `resolver` maps each decoded currency code to its ``MinimalQuantisation``.
    /// Throws `DecodingError.dataCorrupted` if the resolver returns `nil` for any code.
    case dictionary(
        amount: MoneyAmountDecodingStrategy,
        resolver: @Sendable (CurrencyCode) -> MinimalQuantisation?
    )
}

extension MoneyBagDecodingStrategy {

    /// Decode from a bare array with entries in ``AnyMoneyDecodingStrategy/full`` format.
    ///
    /// Equivalent to `.array(entry: .full)`.
    public static var array: Self { .array(entry: .full) }

}

// MARK: - CodingUserInfoKey constants

extension CodingUserInfoKey {

    /// The user-info key for ``MoneyBagEncodingStrategy``.
    ///
    /// Prefer ``JSONEncoder/moneyBagEncodingStrategy`` over setting this key directly.
    public static let moneyBagEncodingStrategy: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "io.swiftmoney.moneybag.encoding-strategy") else {
            preconditionFailure("CodingUserInfoKey creation failed for moneyBagEncodingStrategy")
        }
        return key
    }()

    /// The user-info key for ``MoneyBagDecodingStrategy``.
    ///
    /// Prefer ``JSONDecoder/moneyBagDecodingStrategy`` over setting this key directly.
    public static let moneyBagDecodingStrategy: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "io.swiftmoney.moneybag.decoding-strategy") else {
            preconditionFailure("CodingUserInfoKey creation failed for moneyBagDecodingStrategy")
        }
        return key
    }()
}

// MARK: - JSONEncoder / JSONDecoder convenience properties

extension JSONEncoder {

    /// The strategy used to encode ``MoneyBag`` values.
    ///
    /// Defaults to ``MoneyBagEncodingStrategy/full`` when not set.
    ///
    /// All strategies for a bag with £1.25 GBP and ¥500 JPY:
    ///
    /// ```swift
    /// var encoder = JSONEncoder()
    ///
    /// encoder.moneyBagEncodingStrategy = .full
    /// // {"entries":[{...GBP full...},{...JPY full...}]}   ← default
    ///
    /// encoder.moneyBagEncodingStrategy = .array(entry: .object(amount: .majorUnits))
    /// // [{"currencyCode":"GBP","amount":1.25},{"currencyCode":"JPY","amount":500}]
    ///
    /// encoder.moneyBagEncodingStrategy = .dictionary(amount: .majorUnits)
    /// // {"GBP":1.25,"JPY":500}
    ///
    /// encoder.moneyBagEncodingStrategy = .dictionary(amount: .minorUnits)
    /// // {"GBP":125,"JPY":500}
    /// ```
    public var moneyBagEncodingStrategy: MoneyBagEncodingStrategy {
        get { userInfo[.moneyBagEncodingStrategy] as? MoneyBagEncodingStrategy ?? .full }
        set { userInfo[.moneyBagEncodingStrategy] = newValue }
    }
}

extension JSONDecoder {

    /// The strategy used to decode ``MoneyBag`` values.
    ///
    /// Defaults to ``MoneyBagDecodingStrategy/full`` when not set.
    /// The strategy **must** match the ``MoneyBagEncodingStrategy`` that produced the data.
    ///
    /// All strategies (decoding a bag with GBP and JPY):
    ///
    /// ```swift
    /// var decoder = JSONDecoder()
    ///
    /// decoder.moneyBagDecodingStrategy = .full
    /// // {"entries":[...]}   ← default
    ///
    /// decoder.moneyBagDecodingStrategy = .array(
    ///     entry: .object(amount: .majorUnits, resolver: registry.asResolver()))
    /// // [{"currencyCode":"GBP","amount":1.25},...]
    ///
    /// decoder.moneyBagDecodingStrategy = .dictionary(
    ///     amount: .majorUnits,
    ///     resolver: registry.asResolver())
    /// // {"GBP":1.25,"JPY":500}
    /// ```
    public var moneyBagDecodingStrategy: MoneyBagDecodingStrategy {
        get { userInfo[.moneyBagDecodingStrategy] as? MoneyBagDecodingStrategy ?? .full }
        set { userInfo[.moneyBagDecodingStrategy] = newValue }
    }
}
#endif

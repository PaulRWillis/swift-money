#if canImport(Foundation)
import Foundation

// MARK: - AnyMoneyEncodingStrategy

/// Controls how an ``AnyMoney`` value is encoded.
///
/// Configure the strategy via ``JSONEncoder/anyMoneyEncodingStrategy`` (preferred) or by
/// setting `encoder.userInfo[.anyMoneyEncodingStrategy]` directly.
///
/// All variants for `Money<GBP>(minorUnits: 125).erased` (= £1.25):
///
/// ```swift
/// var encoder = JSONEncoder()
///
/// encoder.anyMoneyEncodingStrategy = .full
/// // {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125}   ← default
/// // Self-contained. Only strategy that preserves AnyMoney.nan.
///
/// encoder.anyMoneyEncodingStrategy = .object
/// // {"currencyCode":"GBP","amount":1.25}
///
/// encoder.anyMoneyEncodingStrategy = .object(amount: .majorUnits)
/// // {"currencyCode":"GBP","amount":1.25}
///
/// encoder.anyMoneyEncodingStrategy = .object(amount: .minorUnits)
/// // {"currencyCode":"GBP","amount":125}  — also preserves nan
///
/// encoder.anyMoneyEncodingStrategy = .object(
///     amount: .string(locale: Locale(identifier: "en_GB")))
/// // {"currencyCode":"GBP","amount":"£1.25"}
/// ```
///
/// - Important: Only ``full`` and `.object(amount: .minorUnits)` preserve ``AnyMoney/isNaN``.
///   All other `.object` sub-strategies throw `EncodingError.invalidValue` for NaN values.
public enum AnyMoneyEncodingStrategy: Sendable {

    /// Encode as a fully self-contained keyed container with `"currencyCode"`,
    /// `"minimalQuantisation"`, and `"minorUnits"`.
    ///
    /// This is the **default** strategy. It is the only top-level strategy that
    /// preserves ``AnyMoney/isNaN`` (encoded as `Int64.min`).
    ///
    /// ```json
    /// {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125}
    /// ```
    case full

    /// Encode as a keyed container with `"currencyCode"` and `"amount"` fields.
    ///
    /// `"minimalQuantisation"` is omitted; the amount format is controlled by
    /// ``MoneyAmountEncodingStrategy``. Use the ``object`` static property as
    /// shorthand for `.object(amount: .majorUnits)`.
    ///
    /// - Important: NaN throws `EncodingError.invalidValue` unless `amount:` is `.minorUnits`.
    case object(amount: MoneyAmountEncodingStrategy)
}

extension AnyMoneyEncodingStrategy {

    /// Encode as `{"currencyCode":"GBP","amount":1.25}`.
    ///
    /// Equivalent to `.object(amount: .majorUnits)`.
    public static var object: Self { .object(amount: .majorUnits) }
}

// MARK: - AnyMoneyDecodingStrategy

/// Controls how an ``AnyMoney`` value is decoded.
///
/// Configure the strategy via ``JSONDecoder/anyMoneyDecodingStrategy`` (preferred) or by
/// setting `decoder.userInfo[.anyMoneyDecodingStrategy]` directly.
///
/// The strategy **must** match the ``AnyMoneyEncodingStrategy`` that produced the data.
///
/// All variants (decoding £1.25, GBP, minQ=100):
///
/// ```swift
/// var decoder = JSONDecoder()
///
/// decoder.anyMoneyDecodingStrategy = .full
/// // {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125}   ← default
///
/// decoder.anyMoneyDecodingStrategy = .object(
///     amount: .majorUnits,
///     resolver: { _ in 100 })
/// // {"currencyCode":"GBP","amount":1.25}
///
/// decoder.anyMoneyDecodingStrategy = .object(
///     amount: .minorUnits,
///     resolver: { _ in 100 })
/// // {"currencyCode":"GBP","amount":125}
///
/// decoder.anyMoneyDecodingStrategy = .object(
///     amount: .string(locale: Locale(identifier: "en_GB")),
///     resolver: { _ in 100 })
/// // {"currencyCode":"GBP","amount":"£1.25"}
/// ```
///
/// - Note: The `resolver` closure is required for `.object` because `"minimalQuantisation"`
///   is absent from the JSON. Use ``CurrencyRegistry`` to build a resolver from a set of
///   currencies without writing a hand-coded switch statement.
public enum AnyMoneyDecodingStrategy: Sendable {

    /// Decode from a fully self-contained keyed container.
    ///
    /// Expects `"currencyCode"`, `"minimalQuantisation"`, and `"minorUnits"`.
    /// This is the **default** strategy.
    case full

    /// Decode from a keyed container with `"currencyCode"` and `"amount"` fields.
    ///
    /// The `resolver` maps the decoded currency code to its ``MinimalQuantisation``.
    /// Throws `DecodingError.dataCorrupted` if the resolver returns `nil` for the
    /// decoded code.
    case object(
        amount: MoneyAmountDecodingStrategy,
        resolver: @Sendable (CurrencyCode) -> MinimalQuantisation?
    )
}

// MARK: - CodingUserInfoKey constants

extension CodingUserInfoKey {

    /// The user-info key for ``AnyMoneyEncodingStrategy``.
    ///
    /// Prefer ``JSONEncoder/anyMoneyEncodingStrategy`` over setting this key directly.
    public static let anyMoneyEncodingStrategy: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "io.swiftmoney.anymoney.encoding-strategy") else {
            preconditionFailure("CodingUserInfoKey creation failed for anyMoneyEncodingStrategy")
        }
        return key
    }()

    /// The user-info key for ``AnyMoneyDecodingStrategy``.
    ///
    /// Prefer ``JSONDecoder/anyMoneyDecodingStrategy`` over setting this key directly.
    public static let anyMoneyDecodingStrategy: CodingUserInfoKey = {
        guard let key = CodingUserInfoKey(rawValue: "io.swiftmoney.anymoney.decoding-strategy") else {
            preconditionFailure("CodingUserInfoKey creation failed for anyMoneyDecodingStrategy")
        }
        return key
    }()
}

// MARK: - JSONEncoder / JSONDecoder convenience properties

extension JSONEncoder {

    /// The strategy used to encode ``AnyMoney`` values.
    ///
    /// Defaults to ``AnyMoneyEncodingStrategy/full`` when not set.
    ///
    /// All strategies for `Money<GBP>(minorUnits: 125).erased` (= £1.25):
    ///
    /// ```swift
    /// var encoder = JSONEncoder()
    ///
    /// encoder.anyMoneyEncodingStrategy = .full
    /// // {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125}   ← default
    ///
    /// encoder.anyMoneyEncodingStrategy = .object
    /// // {"currencyCode":"GBP","amount":1.25}
    ///
    /// encoder.anyMoneyEncodingStrategy = .object(amount: .majorUnits)
    /// // {"currencyCode":"GBP","amount":1.25}
    ///
    /// encoder.anyMoneyEncodingStrategy = .object(amount: .minorUnits)
    /// // {"currencyCode":"GBP","amount":125}
    ///
    /// encoder.anyMoneyEncodingStrategy = .object(
    ///     amount: .string(locale: Locale(identifier: "en_GB")))
    /// // {"currencyCode":"GBP","amount":"£1.25"}
    /// ```
    ///
    /// - Note: Only `.full` and `.object(amount: .minorUnits)` preserve ``AnyMoney/isNaN``.
    public var anyMoneyEncodingStrategy: AnyMoneyEncodingStrategy {
        get { userInfo[.anyMoneyEncodingStrategy] as? AnyMoneyEncodingStrategy ?? .full }
        set { userInfo[.anyMoneyEncodingStrategy] = newValue }
    }
}

extension JSONDecoder {

    /// The strategy used to decode ``AnyMoney`` values.
    ///
    /// Defaults to ``AnyMoneyDecodingStrategy/full`` when not set.
    /// The strategy **must** match the ``AnyMoneyEncodingStrategy`` that produced the data.
    ///
    /// All strategies (decoding £1.25, GBP, minQ=100):
    ///
    /// ```swift
    /// var decoder = JSONDecoder()
    ///
    /// decoder.anyMoneyDecodingStrategy = .full
    /// // {"currencyCode":"GBP","minimalQuantisation":100,"minorUnits":125}   ← default
    ///
    /// decoder.anyMoneyDecodingStrategy = .object(
    ///     amount: .majorUnits,
    ///     resolver: { _ in 100 })
    /// // {"currencyCode":"GBP","amount":1.25}
    ///
    /// decoder.anyMoneyDecodingStrategy = .object(
    ///     amount: .minorUnits,
    ///     resolver: { _ in 100 })
    /// // {"currencyCode":"GBP","amount":125}
    ///
    /// decoder.anyMoneyDecodingStrategy = .object(
    ///     amount: .string(locale: Locale(identifier: "en_GB")),
    ///     resolver: { _ in 100 })
    /// // {"currencyCode":"GBP","amount":"£1.25"}
    /// ```
    ///
    /// - Note: For `.object`, provide a `resolver` that maps `CurrencyCode` to
    ///   ``MinimalQuantisation``. Use ``CurrencyRegistry`` to avoid a hand-coded switch.
    public var anyMoneyDecodingStrategy: AnyMoneyDecodingStrategy {
        get { userInfo[.anyMoneyDecodingStrategy] as? AnyMoneyDecodingStrategy ?? .full }
        set { userInfo[.anyMoneyDecodingStrategy] = newValue }
    }
}
#endif

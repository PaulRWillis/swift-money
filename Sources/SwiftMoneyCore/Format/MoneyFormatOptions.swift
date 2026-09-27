/// The display options that mirror `Decimal.FormatStyle.Currency`'s modifiers, minus the currency code
/// (which the amount carries). Defaults render the exact amount, grouped, with a sign only when negative.
public struct MoneyFormatOptions: Equatable, Hashable, Sendable {
    /// When a sign is written.
    public enum Sign: Equatable, Hashable, Sendable {
        /// A minus for a negative amount, nothing otherwise. The default.
        case automatic
        /// No sign, whatever the amount.
        case never
        /// A plus for a non-negative amount, a minus for a negative one.
        case always
        /// A negative amount in parentheses, a non-negative one plain.
        case accounting
    }

    /// When the decimal separator is written.
    public enum DecimalSeparator: Equatable, Hashable, Sendable {
        /// Written only when fraction digits follow it. The default.
        case automatic
        /// Always written, even for a whole amount.
        case always
    }

    /// Whether the whole digits are grouped, mirroring `Decimal.FormatStyle.Currency`'s grouping.
    public enum Grouping: Equatable, Hashable, Sendable {
        /// Group the whole digits using the format's grouping scheme. The default.
        case automatic
        /// Never group, whatever the format's scheme.
        case never
    }

    /// How many fraction digits are shown.
    public enum Precision: Equatable, Hashable, Sendable {
        /// The currency's own scale, so nothing rounds. The default.
        case currencyScale
        /// A fixed number of fraction digits. Fewer than the currency's scale rounds the shown value by
        /// `rounding`; more pads with zeros.
        case fixed(FractionLength, rounding: RoundingRule)
    }

    public var sign: Sign
    public var grouping: Grouping
    public var decimalSeparator: DecimalSeparator
    public var precision: Precision

    public init(
        sign: Sign = .automatic,
        grouping: Grouping = .automatic,
        decimalSeparator: DecimalSeparator = .automatic,
        precision: Precision = .currencyScale
    ) {
        self.sign = sign
        self.grouping = grouping
        self.decimalSeparator = decimalSeparator
        self.precision = precision
    }
}

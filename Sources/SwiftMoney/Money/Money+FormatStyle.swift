import Foundation

extension Money {
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {
        private let locale: Locale
        private let signDisplayStrategy: Configuration.SignDisplayStrategy

        public typealias Configuration = CurrencyFormatStyleConfiguration

        public init(
            locale: Locale = .autoupdatingCurrent
        ) {
            self.locale = locale

            self.signDisplayStrategy = .automatic
        }

        private init(
            locale: Locale,
            signDisplayStrategy: Configuration.SignDisplayStrategy
        ) {
            self.locale = locale
            self.signDisplayStrategy = signDisplayStrategy
        }

        public func sign(
            strategy: Configuration.SignDisplayStrategy
        ) -> FormatStyle {
            Self.init(
                locale: self.locale,
                signDisplayStrategy: strategy
            )
        }
    }
}

@available(macOS 12.0, *)
extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        value.minorUnits.formatted(
            .currency(code: value.currency.code)
            .locale(self.locale)
            .sign(strategy: self.signDisplayStrategy)
            .presentation(.narrow)
            .scale(1.00 / Double(value.currency.minorUnits))
        )
    }
}

#warning("`.presentation(.narrow) will need to be modifiable. Dollars are automatically marked US$ by default, but this would likely be undesirable for US users. Using `.narrow` means different dollar currencies can be confused with each other.")

extension Money {
    public func formatted() -> String {
        Self.FormatStyle().format(self)
    }
}

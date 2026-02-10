import Foundation

extension Money {
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {
        private let locale: Locale

        public init(
            locale: Locale = .autoupdatingCurrent
        ) {
            self.locale = locale
        }
    }
}

@available(macOS 12.0, *)
extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        value.minorUnits.formatted(
            .currency(code: value.currency.code)
            .locale(self.locale)
            .presentation(.narrow)
            .scale(1.00 / Double(value.currency.minimalQuantisation))
        )
    }
}

#warning("`.presentation(.narrow) will need to be modifiable. Dollars are automatically marked US$ by default, but this would likely be undesirable for US users. Using `.narrow` means different dollar currencies can be confused with each other.")

extension Money {
    public func formatted() -> String {
        Self.FormatStyle().format(self)
    }
}

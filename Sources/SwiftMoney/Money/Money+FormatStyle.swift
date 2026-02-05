import Foundation

extension Money {
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {

        public init() {}
    }
}

@available(macOS 12.0, *)
extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        value.minorUnits.formatted(
            .currency(code: value.currency.code)
            .presentation(.narrow)
            .scale(0.01)
        )
    }
}

#warning("`.presentation(.narrow) will need to be modifiable. Dollars are automatically marked US$ by default, but this would likely be undesirable for US users. Using `.narrow` means different dollar currencies can be confused with each other.")

extension Money {
    public func formatted() -> String {
        Self.FormatStyle().format(self)
    }
}

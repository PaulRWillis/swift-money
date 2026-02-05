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
            .currency(code: "GBP").scale(0.01)
        )
    }
}

extension Money {
    public func formatted() -> String {
        Self.FormatStyle().format(self)
    }
}

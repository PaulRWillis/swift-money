import Foundation

extension Money {
    public struct FormatStyle: Equatable, Hashable, Sendable, Codable {
        private let locale: Locale
        private let signDisplayStrategy: Configuration.SignDisplayStrategy
        private let presentation: Configuration.Presentation

        public typealias Configuration = CurrencyFormatStyleConfiguration

        public init(
            locale: Locale = .autoupdatingCurrent
        ) {
            self.locale = locale

            self.signDisplayStrategy = .automatic
            self.presentation = .standard
        }

        private init(
            locale: Locale,
            signDisplayStrategy: Configuration.SignDisplayStrategy,
            presentation: Configuration.Presentation
        ) {
            self.locale = locale
            self.signDisplayStrategy = signDisplayStrategy
            self.presentation = presentation
        }

//        public var attributed: FormatStyle.Attributed {
//
//        }
//
//        public func grouping(_ group: Configuration.Grouping) -> FormatStyle {
//
//        }
//
//        public func precision(_ p: Configuration.Precision) -> FormatStyle {
//
//        }

        public func sign(
            strategy: Configuration.SignDisplayStrategy
        ) -> FormatStyle {
            Self.init(
                locale: self.locale,
                signDisplayStrategy: strategy,
                presentation: self.presentation
            )
        }

//        public func decimalSeparator(
//            strategy: Configuration.DecimalSeparatorDisplayStrategy
//        ) -> FormatStyle {
//
//        }
//
//        public func rounded(
//            rule: Configuration.RoundingRule = .toNearestOrEven,
//            increment: Int? = nil
//        ) -> FormatStyle {
//
//        }
//
//        public func scale(_ multiplicand: Double) -> FormatStyle {
//
//        }
//
        public func presentation(
            _ p: Configuration.Presentation
        ) -> FormatStyle {
            Self.init(
                locale: self.locale,
                signDisplayStrategy: self.signDisplayStrategy,
                presentation: p
            )
        }
//
//        /// Modifies the format style to use the specified notation.
//        ///
//        /// - Parameter notation: The notation to apply to the format style.
//        /// - Returns: An integer currency format style modified to use the specified notation.
//        @available(macOS 15, iOS 18, tvOS 18, watchOS 11, *)
//        public func notation(
//            _ notation: Configuration.Notation
//        ) -> FormatStyle {
//
//        }
    }
}


/*

 attributed

 decimalSeparator

 grouping

 notation

 precision

 presentation

 rounded

 scale

 sign

 currencyCode

 */

extension Money.FormatStyle: Foundation.FormatStyle {
    public func format(_ value: Money) -> String {
        value.minorUnits.formatted(
            .currency(code: value.currency.code)
            .locale(self.locale)
            .sign(strategy: self.signDisplayStrategy)
            .presentation(self.presentation)
            .scale(1.00 / Double(value.currency.minorUnits))
        )
    }
}

#warning("`.presentation(.narrow) will need to be modifiable. Dollars are automatically marked US$ by default, but this would likely be undesirable for US users. Using `.narrow` means different dollar currencies can be confused with each other.")

#warning("Add tests to ensure this works as expected")
extension Money {
    /// Format `self` using `Money.FormatStyle()`
    public func formatted() -> String {
        Self.FormatStyle().format(self)
    }
}

//extension Money {
//    /// Format `self` with the given format.
//    public func formatted<S: Foundation.FormatStyle>(
//        _ format: S
//    ) -> S.FormatOutput
//    where S.FormatInput == Money {
//        format.format(self)
//    }
//}
//

//extension FormatStyle {
//    public static func sign<C: Currency>() -> Self
//    where Self == Money<C>.FormatStyle {
//        let formatStyle = Money<C>.FormatStyle()
//
//        formatStyle.sign
//
//        return formatStyle
//    }
//}

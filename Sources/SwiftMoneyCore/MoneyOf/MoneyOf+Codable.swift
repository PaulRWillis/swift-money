extension MoneyOf: Codable {
    /// Writes the amount and its currency, as one string unless the encoder asks for otherwise.
    ///
    /// ```swift
    /// GBP(minorUnits: 4_99)                        // "GBP 499"
    /// Money(minorUnits: 499, currency: .jpy)       // "JPY 499"
    /// ```
    ///
    /// Give the encoder a ``MoneyCodingFormat`` to write a different shape.
    ///
    /// - Throws: `EncodingError.invalidValue` where the shape cannot carry this amount: one leaving
    ///   the currency out, where the currency is known only at runtime, or a major units number,
    ///   where the amount is too large for a number to name exactly.
    public func encode(to encoder: any Encoder) throws {
        switch encoder.moneyCodingFormat.shape {
        case let .codedString(units):
            var container = encoder.singleValueContainer()

            try container.encode(codedString(units))

        case let .fields(currencyKey, amountKey, amount):
            var container = encoder.container(keyedBy: MoneyCodingKey.self)
            let key = MoneyCodingKey(amountKey)

            try container.encode(currency.code, forKey: MoneyCodingKey(currencyKey))

            switch amount {
            case .number(.minorUnits):
                try container.encode(minorUnits, forKey: key)

            case .number(.majorUnits):
                try container.encode(majorUnitsNumber(at: encoder), forKey: key)

            case let .string(units):
                try container.encode(amountText(units), forKey: key)
            }

        case let .amountOnly(amount):
            guard Self.impliedStorage != nil else {
                throw EncodingError.invalidValue(self, EncodingError.Context(
                    codingPath: encoder.codingPath,
                    debugDescription: Self.amountOnlyRefusal
                ))
            }

            var container = encoder.singleValueContainer()

            switch amount {
            case .number(.minorUnits):
                try container.encode(minorUnits)

            case .number(.majorUnits):
                try container.encode(majorUnitsNumber(at: encoder))

            case let .string(units):
                try container.encode(amountText(units))
            }
        }
    }

    // The amount in major units, as the only fractional primitive a coder takes.
    private func majorUnitsNumber(at encoder: any Encoder) throws -> Double {
        guard minorUnits.magnitude < exactNumberBound else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: Self.refusalBeyondExactRange(codedString(.minorUnits))
            ))
        }

        return Double(minorUnits) / Double(Int64(currency.unitScale))
    }

    /// Reads an amount, in any form this library writes.
    ///
    /// ```swift
    /// "GBP 499"                          // £4.99, into GBP or into Money
    /// "GBP 4.99"                         // £4.99, into GBP or into Money
    /// "499"                              // £4.99, into GBP only
    /// 499                                // £4.99, into GBP only
    /// {"currency": "GBP", "amount": 499} // £4.99, into GBP or into Money
    /// {"amount": "4.99"}                 // £4.99, into GBP only
    /// ```
    ///
    /// The payload's own shape decides, so no format has to be set to read any of these. The
    /// currency may be left out only where the type names it, and must match where it is given.
    ///
    /// A string says which units it counts, a `.` meaning major units and none meaning the
    /// currency's smallest. A number cannot say, `400` and `400.00` being one JSON number, so it
    /// counts whichever units the format names, the smallest of them unless told otherwise.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the payload is not an amount this currency can
    ///   hold exactly, or leaves out a currency this type cannot supply.
    public init(from decoder: any Decoder) throws {
        // The payload's own shape decides, so nothing has to be configured to read any of them, and
        // a string is tried first because it is what this library writes unless told otherwise. The
        // format supplies only the keys, which nothing else could know.
        let container = try decoder.singleValueContainer()
        let format = decoder.moneyCodingFormat

        if let text = try? container.decode(String.self) {
            self = try Self.fromCodedString(text, in: container)
        } else if let number = WireNumber(in: container) {
            self = try Self.fromBareAmount(number, units: format.units, in: container)
        } else {
            self = try Self.fromFields(decoder, format: format)
        }
    }

    private static func fromCodedString(
        _ text: String,
        in container: SingleValueDecodingContainer
    ) throws -> MoneyOf {
        do {
            return try MoneyOf(codedString: text)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: refusal(of: text, because: error)
            )
        }
    }

    // An amount written on its own, in the currency this type names.
    private static func fromBareAmount(
        _ number: WireNumber,
        units: MoneyCodingFormat.Units,
        in container: SingleValueDecodingContainer
    ) throws -> MoneyOf {
        guard let storage = impliedStorage else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: refusal(forCurrency: nil, in: nil)
            )
        }

        do {
            let amount = try number.minorUnits(in: C.currency(for: storage), units: units)

            return MoneyOf(unchecked: amount, storage: storage)
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: Self.refusal(of: error))
        }
    }

    private static func fromFields(
        _ decoder: any Decoder,
        format: MoneyCodingFormat
    ) throws -> MoneyOf {
        let keys = format.fieldKeys
        let container = try decoder.container(keyedBy: MoneyCodingKey.self)
        let code = try container.decodeIfPresent(CurrencyCode.self, forKey: keys.currency)

        guard let storage = C.storage(forCode: code) else {
            throw DecodingError.dataCorruptedError(
                forKey: keys.currency,
                in: container,
                debugDescription: Self.refusal(forCurrency: code, in: keys.currency.stringValue)
            )
        }

        let currency = C.currency(for: storage)

        if let text = try? container.decode(String.self, forKey: keys.amount) {
            guard let minorUnits = parsedMinorUnits(text, in: currency) else {
                throw DecodingError.dataCorruptedError(
                    forKey: keys.amount,
                    in: container,
                    debugDescription: Self.refusal(of: text, because: .inexactAmount(currency))
                )
            }

            return MoneyOf(unchecked: minorUnits, storage: storage)
        }

        let number = try WireNumber(in: container, forKey: keys.amount)

        do {
            let amount = try number.minorUnits(in: currency, units: format.units)

            return MoneyOf(unchecked: amount, storage: storage)
        } catch {
            throw DecodingError.dataCorruptedError(
                forKey: keys.amount,
                in: container,
                debugDescription: Self.refusal(of: error)
            )
        }
    }

    // What an amount of this type carries when nothing names a currency, and `nil` where the
    // currency is known only at runtime.
    private static var impliedStorage: C.Storage? {
        C.storage(forCode: nil)
    }

    // The currency every amount of this type is in, where its representation fixes one.
    private static var impliedCurrency: Currency? {
        impliedStorage.map(C.currency(for:))
    }

    private static func refusal(of error: WireNumberError) -> String {
        switch error {
        case let .fractionalMinorUnits(currency, value):
            return """
                Read \(value) where a whole number of \(currency.code)'s smallest units was \
                expected. Send the amount in smallest units, or ask for major units with a \
                MoneyCodingFormat.
                """

        case let .inexactAmount(currency, text):
            return refusal(of: text, because: .inexactAmount(currency))

        case let .beyondExactRange(currency, text):
            return refusalBeyondExactRange("\(currency.code) \(text)")
        }
    }

    // Shared by both directions, an amount being unable to cross as a number for the same reason
    // whichever way it is going.
    private static func refusalBeyondExactRange(_ amount: String) -> String {
        """
        \(amount) is too large to cross as a number: at or past \(exactNumberBound) of a currency's \
        smallest units, a number names a neighboring amount instead. Send it as a string.
        """
    }

    // Separate from the reader's unnamed-currency refusal below, the remedy differing: a reader can
    // be given the currency, whereas a writer has to pick a shape that carries one.
    private static var amountOnlyRefusal: String {
        """
        A bare amount does not say which currency it is in, and this one's currency is known only \
        at runtime. Encode into a type that names the currency, or write the currency too with \
        the codedString or fields format.
        """
    }

    // Three failures with three remedies. A currency that cannot be resolved is nothing like an
    // amount written too finely, and telling a caller to write fewer decimals when their currency
    // is the problem sends them the wrong way.
    private static func refusal(
        of text: String,
        because error: CodedStringError
    ) -> String {
        switch error {
        case .unnamedCurrency:
            return "\(refusal(forCurrency: nil, in: nil)) Read in \"\(text)\", where \"GBP 499\" would do."

        case let .unresolvedCurrency(code):
            return "\(refusal(forCurrency: code, in: nil)) Read in \"\(text)\"."

        case let .inexactAmount(currency):
            return """
                Not an amount \(currency.code) can hold exactly: "\(text)". \
                Write it to the precision \(currency.code) divides into, as in "499" or "4.99".
                """
        }
    }

    // Shared by both shapes, since a currency is unusable for the same reasons whether it was read
    // from a field or from the front of a string. `field` names where to look when there was one.
    private static func refusal(
        forCurrency code: CurrencyCode?,
        in field: String?
    ) -> String {
        let place = field.map { " in the \"\($0)\" field" } ?? ""

        guard let code else {
            return """
                No currency named\(place), and this amount can only take one from what it reads. \
                Name the currency, or decode into a type that names it.
                """
        }

        guard let implied = impliedCurrency else {
            return """
                Unknown currency code "\(code)"\(place). Decode into a type that names the currency, \
                or read the code and the amount separately and use Money(string:currency:).
                """
        }

        return """
            Expected \(implied.code) but read "\(code)"\(place). \
            Leave the currency out, or name the one this type holds.
            """
    }
}

extension MoneyOf {
    // A JSON number as it arrived, kept as written until the format says which units it counts.
    private enum WireNumber {
        case whole(MinorUnits)
        case fractional(Double)

        init?(in container: SingleValueDecodingContainer) {
            if let whole = try? container.decode(MinorUnits.self) {
                self = .whole(whole)
            } else if let fractional = try? container.decode(Double.self) {
                self = .fractional(fractional)
            } else {
                return nil
            }
        }

        init(
            in container: KeyedDecodingContainer<MoneyCodingKey>,
            forKey key: MoneyCodingKey
        ) throws {
            if let whole = try? container.decode(MinorUnits.self, forKey: key) {
                self = .whole(whole)
            } else if let fractional = try? container.decode(Double.self, forKey: key) {
                self = .fractional(fractional)
            } else {
                // Neither, so the coder is left to say what it found where a number was expected.
                self = .whole(try container.decode(MinorUnits.self, forKey: key))
            }
        }

        func minorUnits(
            in currency: Currency,
            units: MoneyCodingFormat.Units
        ) throws(WireNumberError) -> MinorUnits {
            let text = try digits(in: currency, units: units)

            guard let amount = parsedMinorUnits(text, in: currency) else {
                throw .inexactAmount(currency, text: text)
            }

            // Only a value a `Double` carried is at risk. Its spacing at a value is about that value
            // times 2^-52, so past the bound two amounts one smallest unit apart are the same
            // `Double`, and the wire quietly names the neighbor.
            if case .fractional = self, amount.magnitude >= exactNumberBound {
                throw .beyondExactRange(currency, text: text)
            }

            return amount
        }

        // The digits the parser reads. A `.` is what tells it they count major units, and neither a
        // whole number nor an expanded exponent carries one.
        private func digits(
            in currency: Currency,
            units: MoneyCodingFormat.Units
        ) throws(WireNumberError) -> String {
            switch self {
            case let .whole(value):
                return units == .majorUnits ? "\(value).0" : "\(value)"

            case let .fractional(value):
                let plain = value.plainDecimalText

                guard units == .majorUnits else {
                    // 400 and 400.00 are one JSON number, so a whole value is taken whichever way it
                    // was written. A real fraction is finer than the smallest unit.
                    guard value == value.rounded(.towardZero) else {
                        throw .fractionalMinorUnits(currency, value: value)
                    }

                    return String(plain.prefix { $0 != "." })
                }

                return plain.contains(".") ? plain : plain + ".0"
            }
        }
    }
}

// Why a JSON number is not an amount.
private enum WireNumberError: Error {
    // A fraction arrived where a whole number of the smallest units was expected.
    case fractionalMinorUnits(Currency, value: Double)

    // The digits are not a whole number of the smallest units of the currency they are in.
    case inexactAmount(Currency, text: String)

    // Past where a `Double` can tell one amount from the next.
    case beyondExactRange(Currency, text: String)
}

// Two amounts one smallest unit apart stay distinguishable in a `Double` only below this. It is not
// a tight limit: 2^52 smallest units is 45 trillion pounds, and 45,035,996 bitcoin against a supply
// capped at 21 million.
private let exactNumberBound: UInt64 = 1 << 52

private extension Double {
    // The shortest decimal that reads back as this value, always written out in full. `description`
    // turns to exponent notation below 0.0001 and at 1e16, which one satoshi reaches at once, and
    // the parser reads digits only.
    var plainDecimalText: String {
        let text = description

        guard let marker = text.firstIndex(where: { $0 == "e" || $0 == "E" }),
              let exponent = Int(text[text.index(after: marker)...])
        else {
            return text
        }

        return String(text[text.startIndex ..< marker]).shiftingPoint(by: exponent)
    }
}

private extension String {
    // The decimal point moved, by carrying digits across it and padding with zeros. No floating
    // point is involved, so nothing here can round.
    func shiftingPoint(by places: Int) -> String {
        var digits = Substring(self)
        let sign = digits.hasPrefix("-") ? "-" : ""

        if digits.hasPrefix("-") || digits.hasPrefix("+") {
            digits.removeFirst()
        }

        let point = digits.firstIndex(of: ".") ?? digits.endIndex
        var whole = String(digits[digits.startIndex ..< point])
        var fraction = point == digits.endIndex ? "" : String(digits[digits.index(after: point)...])

        // Each slice becomes a `String` before it is joined. Some toolchains resolve a `String` and a
        // `Substring` added together and some refuse it, so nothing here relies on that.
        if places >= 0 {
            let carried = min(places, fraction.count)

            whole += String(fraction.prefix(carried)) + String(repeating: "0", count: places - carried)
            fraction = String(fraction.dropFirst(carried))
        } else {
            let carried = min(-places, whole.count)

            fraction = String(repeating: "0", count: -places - carried)
                + String(whole.suffix(carried))
                + fraction
            whole = String(whole.dropLast(carried))
        }

        return sign + (whole.isEmpty ? "0" : whole) + (fraction.isEmpty ? "" : "." + fraction)
    }
}

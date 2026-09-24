import Foundation
import SwiftMoneyCore

/// Parses a General Decimal Arithmetic test file and checks each vector against the fixed-point engine.
///
/// A `.decTest` file is a sequence of directive lines (`key: value`) and test lines
/// (`id operation operand… -> result conditions`), with `--` comments. Only the vectors the engine can
/// faithfully represent are run; the rest are counted as skips with a reason. See `GDASkipReason`.
enum GDATestRunner {

    /// The engine keeps 18 fractional digits (`Fixed`). An operand or result needing more than that would
    /// be rounded on the way in, which would test the harness's rounding rather than the engine's, so such
    /// vectors are skipped.
    private static let maxFractionalDigits = 18

    /// Runs every vector in `url` whose operation is in `operations`, merging the results into one summary.
    static func run(contentsOf url: URL, operations: Set<String>) throws -> GDASummary {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var summary = GDASummary()

        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = stripComment(String(rawLine)).trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            let tokens = tokenize(line)
            // A directive (`rounding:`, `precision:`, …) rather than a test line. Arithmetic vectors are
            // checked for exactness through their conditions, so no directive affects this run.
            guard tokens.count >= 2, !tokens[0].hasSuffix(":") else { continue }

            let operation = tokens[1].lowercased()
            guard operations.contains(operation) else { continue }
            guard let arrow = tokens.firstIndex(of: "->"), arrow + 1 < tokens.count else { continue }

            let operands = Array(tokens[2..<arrow])
            let expected = tokens[arrow + 1]
            let conditions = tokens[(arrow + 2)...].map { $0.lowercased() }

            switch evaluate(operation: operation, operands: operands, expected: expected, conditions: conditions) {
            case .passed:
                summary.recordPass()
            case let .skipped(reason):
                summary.recordSkip(reason)
            case let .failed(detail):
                summary.recordFailure("\(tokens[0]) \(operation): \(detail)")
            }
        }

        return summary
    }

    private enum LineOutcome {
        case passed
        case skipped(GDASkipReason)
        case failed(String)
    }

    private static func evaluate(
        operation: String,
        operands: [String],
        expected: String,
        conditions: [String]
    ) -> LineOutcome {
        if let reason = skipReason(for: conditions) {
            return .skipped(reason)
        }

        switch operation {
        case "add": return binary(operands, expected) { $0 + $1 }
        case "subtract": return binary(operands, expected) { $0 - $1 }
        case "multiply": return binary(operands, expected) { $0 * $1 }
        case "divide": return divide(operands, expected)
        case "min": return binary(operands, expected) { Swift.min($0, $1) }
        case "max": return binary(operands, expected) { Swift.max($0, $1) }
        case "plus": return unary(operands, expected) { $0 }
        case "minus": return unary(operands, expected) { .zero - $0 }
        case "abs": return unary(operands, expected) { $0 < .zero ? .zero - $0 : $0 }
        case "compare": return compare(operands, expected)
        default: return .skipped(.unsupportedOperation)
        }
    }

    // MARK: - Operations

    private static func binary(
        _ operands: [String],
        _ expected: String,
        _ operate: (Fixed, Fixed) -> Fixed
    ) -> LineOutcome {
        guard operands.count == 2 else { return .skipped(.unsupportedOperation) }
        return withValues(operands[0], operands[1], expected) { a, b, e in
            let result = operate(a, b)
            return result == e ? .passed : .failed("expected \(expected), got \(result)")
        }
    }

    private static func divide(_ operands: [String], _ expected: String) -> LineOutcome {
        guard operands.count == 2 else { return .skipped(.unsupportedOperation) }
        return withValues(operands[0], operands[1], expected) { a, b, e in
            // A zero divisor with no condition would trap; the corpus flags real ones with
            // division_by_zero, already skipped above, so guard defensively.
            guard b != .zero else { return .skipped(.expectsTrap) }
            let result = a / b
            return result == e ? .passed : .failed("expected \(expected), got \(result)")
        }
    }

    private static func unary(
        _ operands: [String],
        _ expected: String,
        _ operate: (Fixed) -> Fixed
    ) -> LineOutcome {
        guard operands.count == 1 else { return .skipped(.unsupportedOperation) }
        switch (operand(operands[0]), operand(expected)) {
        case let (.value(a), .value(e)):
            let result = operate(a)
            return result == e ? .passed : .failed("expected \(expected), got \(result)")
        case let (a, e):
            return .skipped(firstSkip(a, e))
        }
    }

    private static func compare(_ operands: [String], _ expected: String) -> LineOutcome {
        guard operands.count == 2 else { return .skipped(.unsupportedOperation) }
        switch (operand(operands[0]), operand(operands[1])) {
        case let (.value(a), .value(b)):
            let result = a < b ? -1 : (a > b ? 1 : 0)
            // An unordered comparison yields NaN, whose operand would already have been skipped.
            guard let e = Int(expected) else { return .skipped(.notRepresentable) }
            return result == e ? .passed : .failed("expected \(expected), got \(result)")
        case let (a, b):
            return .skipped(firstSkip(a, b))
        }
    }

    /// Parses three operands and runs `body` only when all three are representable, otherwise skips with the
    /// first reason.
    private static func withValues(
        _ first: String,
        _ second: String,
        _ third: String,
        _ body: (Fixed, Fixed, Fixed) -> LineOutcome
    ) -> LineOutcome {
        switch (operand(first), operand(second), operand(third)) {
        case let (.value(a), .value(b), .value(c)):
            return body(a, b, c)
        case let (a, b, c):
            return .skipped(firstSkip(a, b, c))
        }
    }

    // MARK: - Parsing

    private enum ParsedOperand {
        case value(Fixed)
        case skip(GDASkipReason)
    }

    private static func operand(_ token: String) -> ParsedOperand {
        switch parseNumber(token) {
        case let .value(fixed): return .value(fixed)
        case .special: return .skip(.notRepresentable)
        case .outOfRange: return .skip(.outOfRange)
        case .tooPrecise: return .skip(.precision)
        }
    }

    private enum NumberParse {
        case value(Fixed)
        case special
        case outOfRange
        case tooPrecise
    }

    private static func parseNumber(_ token: String) -> NumberParse {
        let lowered = token.lowercased()
        guard !lowered.contains("nan"), !lowered.contains("inf"), !lowered.hasPrefix("#") else {
            return .special
        }

        var body = Substring(token)
        var negative = false
        if body.first == "+" {
            body = body.dropFirst()
        } else if body.first == "-" {
            negative = true
            body = body.dropFirst()
        }

        var exponent = 0
        if let marker = body.firstIndex(where: { $0 == "e" || $0 == "E" }) {
            guard let parsed = Int(body[body.index(after: marker)...]) else { return .special }
            exponent = parsed
            body = body[..<marker]
        }

        var digits = ""
        var fractionDigits = 0
        var sawPoint = false
        for character in body {
            if character == "." {
                if sawPoint { return .special }
                sawPoint = true
            } else if character.isNumber {
                digits.append(character)
                if sawPoint { fractionDigits += 1 }
            } else {
                return .special
            }
        }
        guard !digits.isEmpty else { return .special }

        exponent -= fractionDigits
        guard -exponent <= maxFractionalDigits else { return .tooPrecise }
        guard let magnitude = Int128(digits) else { return .outOfRange }
        let significand = negative ? -magnitude : magnitude
        guard let fixed = Fixed(significand: significand, exponent: exponent) else { return .outOfRange }
        return .value(fixed)
    }

    // MARK: - Conditions and helpers

    private static func skipReason(for conditions: [String]) -> GDASkipReason? {
        let traps: Set = [
            "overflow", "underflow", "division_by_zero", "invalid_operation",
            "division_impossible", "division_undefined", "conversion_syntax", "insufficient_storage",
        ]
        if conditions.contains(where: traps.contains) { return .expectsTrap }
        // Inexact / Rounded / Clamped / Subnormal all mean the corpus rounded the result to a decimal
        // significance the fixed-point engine does not model, so the values would legitimately differ.
        if conditions.contains(where: ["inexact", "rounded", "clamped", "subnormal"].contains) {
            return .precision
        }
        return nil
    }

    private static func firstSkip(_ results: ParsedOperand...) -> GDASkipReason {
        for result in results {
            if case let .skip(reason) = result { return reason }
        }
        return .notRepresentable  // coverage:ignore — only reached if every operand parsed, which the caller rules out
    }

    private static func stripComment(_ line: String) -> String {
        guard let range = line.range(of: "--") else { return line }
        return String(line[..<range.lowerBound])
    }

    private static func tokenize(_ line: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuote = false

        for character in line {
            if character == "'" {
                inQuote.toggle()
            } else if character == " " || character == "\t", !inQuote {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}

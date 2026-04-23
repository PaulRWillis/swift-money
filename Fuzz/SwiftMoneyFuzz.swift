// Fuzz target for SwiftMoney using libFuzzer.
//
// Build:  bash Fuzz/run.sh
// Run:    Fuzz/fuzz-swiftmoney [corpus_dir]
//
// The fuzzer generates random byte buffers and uses them to construct
// Money values and operations. It validates invariants that must hold
// for ALL inputs — any violation is a bug.
//
// Platform: Linux only — Swift's -sanitize=fuzzer requires the open-source
//           Swift toolchain, not available in Xcode on macOS.
//
// Build strategy: The library is compiled WITHOUT sanitizers; only this
// fuzz harness is compiled WITH -sanitize=fuzzer. This isolates UBSan
// instrumentation to the harness, avoiding false positives from
// well-defined Swift integer operations (Int128, negation) in the library.
// As a consequence, this file uses only public SwiftMoney API.
//
// IMPORTANT: Currency types used here (GBP, USD, JPY) are defined in the
// library module, NOT in this file. This ensures generic specializations
// (e.g. Money<GBP>.multiplied(by:)) happen in the library's compilation
// unit — without UBSan. Defining custom currency types here would cause
// specializations in the harness module, re-introducing UBSan false positives.

import SwiftMoney
import Foundation

// MARK: - Input parsing

/// Reads a fixed number of bytes from the fuzzer buffer, advancing the offset.
private struct FuzzReader {
    let data: UnsafeRawBufferPointer
    var offset: Int = 0

    var remaining: Int { data.count - offset }

    mutating func readByte() -> UInt8? {
        guard offset < data.count else { return nil }
        defer { offset += 1 }
        return data[offset]
    }

    mutating func readInt64() -> Int64? {
        guard remaining >= 8 else { return nil }
        // Use UInt64 for bit manipulation to avoid UBSan signed-overflow
        // false positives when shifting into the sign bit.
        var value: UInt64 = 0
        for i in 0..<8 {
            value |= UInt64(data[offset + i]) << (i * 8)
        }
        offset += 8
        return Int64(bitPattern: value)
    }
}

// MARK: - Operations

private enum Operation: UInt8 {
    case add = 0
    case subtract = 1
    case multiplyInt = 2
    case negate = 3
    case compare = 4
    case codable = 5
    case distribution = 6
    case fractionalRate = 7
    case exchangeRate = 8
    case hash = 9
}

private let operationCount: UInt8 = 10

// MARK: - Helpers

/// Safe maximum for addition/subtraction operands to prevent overflow.
/// |a| + |b| < Int64.max when both are below this threshold.
private let safeRange = Int64.max / 2

/// Clamps a raw Int64 to the safe range for addition/subtraction,
/// while also excluding the NaN sentinel.
private func safeMoney(_ raw: Int64) -> Money<GBP> {
    var v = raw
    // Exclude NaN sentinel
    if v == .min { v = .min + 1 }
    // Clamp to safe range
    if v > safeRange { v = safeRange }
    if v < -safeRange { v = -safeRange }
    return Money<GBP>(minorUnits: v)
}

/// Creates a Money value from raw Int64, excluding only the NaN sentinel.
private func money(_ raw: Int64) -> Money<GBP> {
    let v = raw == .min ? raw + 1 : raw
    return Money<GBP>(minorUnits: v)
}

// MARK: - Fuzz entry point

@_cdecl("LLVMFuzzerTestOneInput")
public func fuzzTest(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
    guard count >= 10 else { return 0 }

    var reader = FuzzReader(data: UnsafeRawBufferPointer(start: start, count: count))
    guard let opByte = reader.readByte(),
          let rawA = reader.readInt64() else { return 0 }

    let op = Operation(rawValue: opByte % operationCount) ?? .add

    switch op {

    // ── Addition ──────────────────────────────────────────────────────
    case .add:
        guard let rawB = reader.readInt64() else { return 0 }
        let a = safeMoney(rawA)
        let b = safeMoney(rawB)

        let sum = a + b

        // INVARIANT: Addition is commutative
        let reverseSum = b + a
        precondition(sum == reverseSum,
                     "Addition not commutative: \(a) + \(b) != \(b) + \(a)")

        // INVARIANT: Additive identity
        let addZero = a + .zero
        precondition(addZero == a,
                     "Additive identity failed: \(a) + 0 = \(addZero)")

        // INVARIANT: Non-NaN inputs never produce NaN
        precondition(!sum.isNaN,
                     "Addition of non-NaN inputs produced NaN")

    // ── Subtraction ───────────────────────────────────────────────────
    case .subtract:
        guard let rawB = reader.readInt64() else { return 0 }
        let a = safeMoney(rawA)
        let b = safeMoney(rawB)

        let diff = a - b

        // INVARIANT: a - b == -(b - a) (anti-commutativity)
        let reverseDiff = b - a
        // Use wrapping negate to avoid UBSan false positive on the harness side
        let negStorage = 0 &- reverseDiff.minorUnits
        guard negStorage != Int64.min else { return 0 }
        let negReverse = Money<GBP>(minorUnits: negStorage)
        precondition(diff == negReverse,
                     "Subtraction anti-commutativity failed: \(a) - \(b) != -(\(b) - \(a))")

        // INVARIANT: Subtractive identity
        let subZero = a - .zero
        precondition(subZero == a,
                     "Subtractive identity failed: \(a) - 0 = \(subZero)")

        // INVARIANT: Non-NaN inputs never produce NaN
        precondition(!diff.isNaN,
                     "Subtraction of non-NaN inputs produced NaN")

    // ── Integer multiplication ────────────────────────────────────────
    case .multiplyInt:
        guard let rawB = reader.readInt64() else { return 0 }
        let a = money(rawA)

        // Constrain multiplier to small range to avoid overflow
        let multiplier = (rawB % 201) - 100  // range: -100...100

        // Check for overflow before calling trapping operator
        let (result, overflow) = a.minorUnits.multipliedReportingOverflow(by: multiplier)
        guard !overflow, result != .min else { return 0 }

        let product = a * multiplier

        // INVARIANT: Commutativity: money * int == int * money
        let reverse = multiplier * a
        precondition(product == reverse,
                     "Integer multiplication not commutative: \(a) * \(multiplier) != \(multiplier) * \(a)")

        // INVARIANT: Multiplicative identity
        let mulOne = a * Int64(1)
        precondition(mulOne == a,
                     "Multiplicative identity failed: \(a) * 1 = \(mulOne)")

        // INVARIANT: Zero annihilation
        let mulZero = a * Int64(0)
        precondition(mulZero == .zero,
                     "Zero annihilation failed: \(a) * 0 = \(mulZero)")

        // INVARIANT: Non-NaN inputs never produce NaN
        precondition(!product.isNaN,
                     "Integer multiplication of non-NaN inputs produced NaN")

    // ── Negation ──────────────────────────────────────────────────────
    case .negate:
        let a = safeMoney(rawA)

        // Use wrapping negate to avoid UBSan false positive on the harness side
        let negStorage = 0 &- a.minorUnits
        guard negStorage != Int64.min else { return 0 }  // skip if negation hits NaN sentinel
        let neg = Money<GBP>(minorUnits: negStorage)

        let doubleNegStorage = 0 &- neg.minorUnits
        guard doubleNegStorage != Int64.min else { return 0 }
        let doubleNeg = Money<GBP>(minorUnits: doubleNegStorage)

        // INVARIANT: Double negation is identity
        precondition(doubleNeg == a,
                     "Double negation failed: \(a) -> \(neg) -> \(doubleNeg)")

        // INVARIANT: a + (-a) == 0
        let sum = a + neg
        precondition(sum == .zero,
                     "a + (-a) != 0: \(a) + \(neg) = \(sum)")

    // ── Comparison ────────────────────────────────────────────────────
    case .compare:
        guard let rawB = reader.readInt64() else { return 0 }
        let a = money(rawA)
        let b = money(rawB)

        let aLTb = a < b
        let bLTa = b < a
        let aEQb = a == b

        // INVARIANT: Strict total order — exactly one must be true
        let trueCount = (aLTb ? 1 : 0) + (bLTa ? 1 : 0) + (aEQb ? 1 : 0)
        precondition(trueCount == 1,
                     "Strict total order violated: a=\(a) b=\(b) a<b=\(aLTb) b<a=\(bLTa) a==b=\(aEQb)")

        // INVARIANT: Consistent with raw storage ordering
        if a.minorUnits < b.minorUnits {
            precondition(aLTb, "Storage ordering inconsistent with Comparable")
        } else if a.minorUnits > b.minorUnits {
            precondition(bLTa, "Storage ordering inconsistent with Comparable")
        } else {
            precondition(aEQb, "Storage equality inconsistent with Equatable")
        }

    // ── Codable round-trip ────────────────────────────────────────────
    case .codable:
        let a = money(rawA)

        let encoder = JSONEncoder()
        encoder.moneyEncodingStrategy = .minorUnits
        let decoder = JSONDecoder()
        decoder.moneyDecodingStrategy = .minorUnits

        guard let data = try? encoder.encode(a) else { return 0 }
        guard let decoded = try? decoder.decode(Money<GBP>.self, from: data) else { return 0 }

        // INVARIANT: Codable round-trip preserves value
        precondition(decoded == a,
                     "Codable round-trip failed: \(a) -> \(decoded)")

    // ── Distribution ──────────────────────────────────────────────────
    case .distribution:
        let a = money(rawA)
        guard let partsByte = reader.readByte() else { return 0 }

        // Constrain parts to 1...255
        let n = Int(partsByte) + 1
        let parts = DistributionParts(n)

        // Skip if division would overflow (near Int64.min / 1)
        guard a.minorUnits != (.min + 1) || n != 1 else { return 0 }

        let dist = a.distributed(into: parts)

        // INVARIANT: Sum of distribution equals original
        precondition(dist.sum == a,
                     "Distribution sum invariant failed: \(dist.sum) != \(a)")

        // INVARIANT: Total count equals requested parts
        precondition(dist.totalCount == n,
                     "Distribution count mismatch: \(dist.totalCount) != \(n)")

        // INVARIANT: For uneven distribution, larger > smaller
        if case let .uneven(larger, largerCount, smaller, smallerCount) = dist {
            precondition(larger > smaller || larger < smaller,
                         "Uneven distribution has equal shares")
            precondition(largerCount + smallerCount == n,
                         "Uneven count mismatch: \(largerCount) + \(smallerCount) != \(n)")
            precondition(largerCount > 0 && smallerCount > 0,
                         "Uneven distribution has zero count")
        }

    // ── FractionalRate GCD reduction ──────────────────────────────────
    case .fractionalRate:
        guard let rawB = reader.readInt64() else { return 0 }

        // FractionalRate requires denominator > 0 and numerator != Int64.min.
        // Use bitwise AND to clear sign bit — avoids abs(Int64.min) UBSan trap.
        let numerator = rawA == .min ? rawA + 1 : rawA
        let denominator = max(1, rawB & Int64.max)

        guard let rate = FractionalRate(numerator: numerator, denominator: denominator) else {
            return 0
        }

        // INVARIANT: Stored fraction is GCD-reduced
        let absNum = rate.numeratorValue < 0 ? -rate.numeratorValue : rate.numeratorValue
        let den = rate.denominatorValue

        if absNum == 0 {
            // 0/1 is the canonical form for zero
            precondition(den == 1,
                         "Zero rate not canonical: 0/\(den)")
        } else {
            // gcd(|numerator|, denominator) must be 1
            let g = gcdForFuzz(absNum, den)
            precondition(g == 1,
                         "FractionalRate not fully reduced: \(rate.numeratorValue)/\(den), gcd=\(g)")
        }

        // INVARIANT: Denominator is always positive
        precondition(rate.denominatorValue > 0,
                     "FractionalRate denominator is not positive: \(rate.denominatorValue)")

    // ── ExchangeRate ──────────────────────────────────────────────────
    case .exchangeRate:
        guard let rawB = reader.readInt64() else { return 0 }

        // ExchangeRate requires both values > 0.
        // Use bitwise AND to clear sign bit — avoids abs(Int64.min) UBSan trap.
        let from = max(1, rawA & Int64.max)
        let to = max(1, rawB & Int64.max)

        guard let rate = ExchangeRate<GBP, USD>(from: from, to: to) else {
            return 0
        }

        // Create a money value safe for conversion (avoid overflow in multiply)
        let moneyRaw = (rawA % 1_000_000) + 1  // small positive value
        let moneyValue = Money<GBP>(minorUnits: moneyRaw > 0 ? moneyRaw : 1)

        // INVARIANT: Conversion doesn't crash and result is not NaN
        let converted = rate.convert(moneyValue)
        precondition(!converted.isNaN,
                     "Exchange rate conversion produced NaN from non-NaN input")

    // ── Hash consistency ──────────────────────────────────────────────
    case .hash:
        let a = money(rawA)
        let b = Money<GBP>(minorUnits: a.minorUnits)

        // INVARIANT: Equal values have equal hashes
        precondition(a == b)
        var h1 = Hasher()
        var h2 = Hasher()
        h1.combine(a)
        h2.combine(b)
        precondition(h1.finalize() == h2.finalize(),
                     "Equal values have different hashes: \(a)")
    }

    return 0
}

// MARK: - Private helpers

/// Euclidean GCD for fuzz verification. Both inputs must be > 0.
private func gcdForFuzz(_ a: Int64, _ b: Int64) -> Int64 {
    var a = a
    var b = b
    while b != 0 {
        let t = b
        b = a % b
        a = t
    }
    return a
}

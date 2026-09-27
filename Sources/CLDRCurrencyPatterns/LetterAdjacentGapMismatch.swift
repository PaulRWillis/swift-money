/// The gap between the currency and the digits in a mark-stripped positive subpattern, given the side
/// the currency sits on — `nil` when the pattern carries no currency placeholder or no digit to place
/// one against.
public func patternGap(ofStrippedPositive strippedPositive: String, side: CurrencySide) -> String? {
    let numberCharacters: Set<Character> = ["#", "0", ",", "."]

    guard let symbolIndex = strippedPositive.firstIndex(of: "¤") else {
        return nil
    }

    switch side {
    case .leading:
        guard let firstNumber = strippedPositive.firstIndex(where: { numberCharacters.contains($0) }) else {
            return nil
        }
        return String(strippedPositive[strippedPositive.index(after: symbolIndex) ..< firstNumber])
    case .trailing:
        guard let lastNumber = strippedPositive.lastIndex(where: { numberCharacters.contains($0) }) else {
            return nil
        }
        return String(strippedPositive[strippedPositive.index(after: lastNumber) ..< symbolIndex])
    }
}

/// Whether a letter-adjacent pattern's own gap would render wrong through the plain pattern's column.
///
/// A letter-adjacent symbol always renders through the *plain* pattern's gap — its own literal gap
/// when it has one, else `insertBetween` (CLDR's `currencySpacing` insertion, which always applies for
/// a letter-adjacent boundary once that literal gap is empty, since a letter is never a currency
/// symbol or separator) — never through its own letter-adjacent pattern's literal gap directly. So a
/// letter-adjacent pattern whose own gap differs from *that* — not from the plain pattern's raw text,
/// which the insertion may legitimately differ from without anything rendering wrong — cannot be
/// represented without the wrong gap shipping.
///
/// - Returns: `nil` when either pattern carries no currency placeholder or no digit to place one
///   against, which a caller reports as its own fault rather than this predicate's.
public func letterAdjacentGapWouldMismatch(
    plainPositive: String,
    plainSide: CurrencySide,
    letterAdjacentPositive: String,
    letterAdjacentSide: CurrencySide,
    insertBetween: String
) -> Bool? {
    guard
        let plainGap = patternGap(ofStrippedPositive: plainPositive, side: plainSide),
        let letterAdjacentGap = patternGap(ofStrippedPositive: letterAdjacentPositive, side: letterAdjacentSide)
    else {
        return nil
    }

    let expected = plainGap.isEmpty ? insertBetween : plainGap
    return letterAdjacentGap != expected
}

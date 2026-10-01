/// Returns a runtime range's bounds as amounts, joined by the operator that builds the range, with
/// optional text before and after.
///
/// - Parameters:
///   - lower: The range's lower bound.
///   - separator: The operator between the bounds, such as `"..."`.
///   - upper: The range's upper bound.
///   - opening: The text before the lower bound, such as a type name and `(`.
///   - closing: The text after the upper bound.
/// - Returns: The joined text, such as `"GBP 10.00...GBP 250.00"`.
func rangeDescription(
    _ lower: Money,
    _ separator: StaticString,
    _ upper: Money,
    opening: StaticString = "",
    closing: StaticString = ""
) -> String {
    var lowerText = lower.description
    var upperText = upper.description
    let length = opening.utf8CodeUnitCount + lowerText.utf8.count + separator.utf8CodeUnitCount
        + upperText.utf8.count + closing.utf8CodeUnitCount

    // One buffer sized exactly: `+` builds an intermediate string and grows it through the generic
    // append path, and reserving the length then appending measured slower than `+`.
    return String(unsafeUninitializedCapacity: length) { buffer in
        var offset = 0

        opening.withUTF8Buffer { copy($0, into: buffer, at: &offset) }
        lowerText.withUTF8 { copy($0, into: buffer, at: &offset) }
        separator.withUTF8Buffer { copy($0, into: buffer, at: &offset) }
        upperText.withUTF8 { copy($0, into: buffer, at: &offset) }
        closing.withUTF8Buffer { copy($0, into: buffer, at: &offset) }

        return offset
    }
}

/// Copies bytes into a buffer at an offset, and moves the offset past them.
///
/// - Parameters:
///   - bytes: The bytes to copy.
///   - buffer: The buffer to copy them into.
///   - offset: Where in `buffer` the copy starts; on return, just past the last byte copied.
/// - Precondition: `buffer` must have room for `bytes` from `offset`.
private func copy(
    _ bytes: UnsafeBufferPointer<UInt8>,
    into buffer: UnsafeMutableBufferPointer<UInt8>,
    at offset: inout Int
) {
    let end = offset + bytes.count
    _ = UnsafeMutableBufferPointer(rebasing: buffer[offset ..< end]).initialize(fromContentsOf: bytes)
    offset = end
}

// A runtime range's bounds as amounts, joined by the operator that builds the range: "GBP 10.00...GBP
// 250.00". Both range types describe themselves this way.
//
// Written into one buffer sized exactly, rather than joined with two `+`, which build an intermediate
// string and grow it through the generic append path. Reserving the length and appending cost more
// than the `+` did. A range's description is longer than fifteen bytes, so the result itself allocates.
func rangeDescription(
    _ lower: Money,
    _ separator: StaticString,
    _ upper: Money
) -> String {
    var lowerText = lower.description
    var upperText = upper.description
    let length = lowerText.utf8.count + separator.utf8CodeUnitCount + upperText.utf8.count

    return String(unsafeUninitializedCapacity: length) { buffer in
        var offset = 0

        lowerText.withUTF8 { copy($0, into: buffer, at: &offset) }
        separator.withUTF8Buffer { copy($0, into: buffer, at: &offset) }
        upperText.withUTF8 { copy($0, into: buffer, at: &offset) }

        return offset
    }
}

private func copy(
    _ bytes: UnsafeBufferPointer<UInt8>,
    into buffer: UnsafeMutableBufferPointer<UInt8>,
    at offset: inout Int
) {
    let end = offset + bytes.count
    _ = UnsafeMutableBufferPointer(rebasing: buffer[offset ..< end]).initialize(fromContentsOf: bytes)
    offset = end
}

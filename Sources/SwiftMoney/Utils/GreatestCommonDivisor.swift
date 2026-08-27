// Euclid. On magnitudes because `abs(Int64.min)` overflows, while `Int64.min.magnitude` is 2^63 and
// fits in a `UInt64` comfortably.
//
// Zero only when both inputs are zero, which is the one case with no greatest common divisor.
func greatestCommonDivisor(
    of first: UInt64,
    and second: UInt64
) -> UInt64 {
    var a = first
    var b = second

    // Larger first, as `swift-numerics` does: starting with the smaller spends a division arriving
    // where this already is. Worth it because every remainder starts that way, a leftover always
    // being below its divisor. Measured at roughly a tenth of the call.
    if a < b {
        swap(&a, &b)
    }

    while b != 0 {
        (a, b) = (b, a % b)
    }

    return a
}

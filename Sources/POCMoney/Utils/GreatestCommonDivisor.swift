// Euclidean greatest common divisor.
//
// Takes magnitudes rather than signed values so that `Int64.min` can be reduced: `abs(Int64.min)`
// overflows, but `Int64.min.magnitude` is 2^63, which fits in `UInt64` comfortably.
//
// Returns 1 rather than 0 when both arguments are zero, so a caller can always divide by the result.
func greatestCommonDivisor(_ a: UInt64, _ b: UInt64) -> UInt64 {
    var a = a
    var b = b

    while b != 0 {
        (a, b) = (b, a % b)
    }

    return a == 0 ? 1 : a
}

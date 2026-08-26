extension Int128 {
    // Ten raised to `exponent`, or `nil` when the exponent is negative or the result overflows Int128.
    static func powerOfTen(_ exponent: Int) -> Int128? {
        guard exponent >= 0 else {
            return nil
        }

        let radix: Int128 = 10
        var result: Int128 = 1
        for _ in 0 ..< exponent {
            let (next, overflow) = result.multipliedReportingOverflow(by: radix)
            guard !overflow else {
                return nil
            }
            result = next
        }

        return result
    }
}

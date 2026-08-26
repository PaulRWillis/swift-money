extension Fixed {
    // Same scale, so the raw values add directly. Traps if the true result is out of range.
    package static func + (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (sum, overflow) = lhs.raw.addingReportingOverflow(rhs.raw)
        precondition(!overflow, "Fixed addition overflowed")

        return Fixed(raw: sum)
    }

    package static func - (lhs: Fixed, rhs: Fixed) -> Fixed {
        let (difference, overflow) = lhs.raw.subtractingReportingOverflow(rhs.raw)
        precondition(!overflow, "Fixed subtraction overflowed")

        return Fixed(raw: difference)
    }
}

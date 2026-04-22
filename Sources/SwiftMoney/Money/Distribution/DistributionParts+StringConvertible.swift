// MARK: - CustomStringConvertible

extension DistributionParts: CustomStringConvertible {
    /// The number of parts as a decimal string, e.g. `"3"`.
    public var description: String { String(_value) }
}

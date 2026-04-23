// MARK: - CustomStringConvertible

extension MinimalQuantisation: CustomStringConvertible {
    /// The quantisation as a decimal string, e.g. `"100"`.
    public var description: String { String(_value) }
}

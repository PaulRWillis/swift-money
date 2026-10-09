/// A type with a zero value that its other values can be compared with.
@usableFromInline
protocol ZeroRepresentable: Equatable {
    /// The zero value.
    static var zero: Self { get }
}

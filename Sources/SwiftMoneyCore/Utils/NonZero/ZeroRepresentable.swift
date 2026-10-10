/// A type with a zero value.
@usableFromInline
protocol ZeroRepresentable: Equatable {
    /// The zero value.
    static var zero: Self { get }
}

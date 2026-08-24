/// Consumes a value so that a trap is not optimized away.
///
/// The Foundation test target's copy of the helper in `Tests/SwiftMoneyTests/BlackHole.swift`,
/// which carries the full reasoning. The short version: the optimizer can delete a call whose
/// result is unused, and a `preconditionFailure` inside that call goes with it, because Swift
/// leaves program-termination paths out of its effects analysis. Every test that asserts a trap
/// needs this, or it passes in debug and fails under `swift test -c release`.
///
/// `@_optimize(none)` is load-bearing, not decoration.
@inline(never)
@_optimize(none)
func blackHole<T>(_ value: T) {}

/// Consumes a value so that trapping arithmetic is not optimized away.
///
/// An overflow check is removed along with the arithmetic when its result is unused, so
/// `_ = GBP.max + GBP(minorUnits: 1)` does not trap in a release build. Passing the result here keeps the
/// arithmetic, and therefore the trap, in the generated code.
///
/// Required by every test that asserts a trap on overflow. Without it those tests pass in debug and
/// fail under `swift test -c release`.
///
/// `@_optimize(none)` is load-bearing, not decoration. Without it the optimizer can delete a call
/// whose result is unused, and a `preconditionFailure` inside that call goes with it — Swift excludes
/// program-termination paths from its effects analysis, so they do not count as a side effect worth
/// preserving. Arithmetic overflow survives either way, being a distinct instruction, which is why the
/// gap stayed hidden until a trap came from an explicit `preconditionFailure`.
///
/// - Note: Still not a general optimization barrier — it keeps the *call* alive, not the value. A
///   benchmark needs a sink that writes to memory.
@inline(never)
@_optimize(none)
func blackHole<T>(_ value: T) {}

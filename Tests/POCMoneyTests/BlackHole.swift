/// Consumes a value so that trapping arithmetic is not optimised away.
///
/// An overflow check is removed along with the arithmetic when its result is unused, so
/// `_ = GBP.max + GBP(1)` does not trap in a release build. Passing the result here keeps the
/// arithmetic, and therefore the trap, in the generated code.
///
/// Required by every test that asserts a trap on overflow. Without it those tests pass in debug and
/// fail under `swift test -c release`.
///
/// - Note: Not a general optimisation barrier. This function has no side effects, so a call whose
///   argument is pure can still be deleted — only *trapping* work is reliably kept alive. A
///   benchmark needs a sink that writes to memory.
@inline(never)
func blackHole<T>(_ value: T) {}

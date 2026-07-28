/// Consumes a value so the optimiser cannot discard the work that produced it.
///
/// Swift's overflow checks are removed along with the arithmetic when a result is unused, so
/// `_ = GBP.max + GBP(1)` does not trap in a release build. Passing the result here keeps it alive:
/// the call cannot be inlined away, so the argument must be computed.
///
/// Required by every test that asserts a trap on overflow. Without it those tests pass in debug and
/// fail under `swift test -c release`.
@inline(never)
func blackHole<T>(_ value: T) {}

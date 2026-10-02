// What settling does to a truncated magnitude: keep it, or step it one away from zero.
@usableFromInline
enum RoundingStep {
    case keep
    case awayFromZero
}

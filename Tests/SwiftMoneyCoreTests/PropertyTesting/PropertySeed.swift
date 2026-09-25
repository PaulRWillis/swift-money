// The fixed seeds and corpus size the property suites draw with, so every run on every machine sees the
// same cases. A seed carries no meaning beyond being distinct from the others; they are written as plain
// hexadecimal to read as opaque labels rather than as quantities.
enum PropertySeed {
    // How many random cases each property draws, on top of its hand-written edge corpus. Large enough
    // that a counterexample is very likely caught, small enough that the whole suite stays sub-second.
    static let sampleCount = 256

    static let additive: UInt64 = 0xA001
    static let scaling: UInt64 = 0xB002
    static let split: UInt64 = 0xC003
    static let weightedSplit: UInt64 = 0xD004
    static let unrounded: UInt64 = 0xE005
    static let exchangeRate: UInt64 = 0xF006
    static let roundTrip: UInt64 = 0x1007
    static let proportion: UInt64 = 0x2008
}

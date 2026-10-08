// The fixed seeds and corpus size the property suites draw with, so every run on every machine sees the
// same cases. A seed carries no meaning beyond being distinct from the others; they are written as plain
// hexadecimal to read as opaque labels rather than as quantities.
package enum PropertySeed {
    // How many random cases each property draws, on top of its hand-written edge corpus. Large enough
    // that a counterexample is very likely caught, small enough that the whole suite stays sub-second.
    package static let sampleCount = 256

    package static let additive: UInt64 = 0xA001
    package static let scaling: UInt64 = 0xB002
    package static let split: UInt64 = 0xC003
    package static let weightedSplit: UInt64 = 0xD004
    package static let unrounded: UInt64 = 0xE005
    package static let exchangeRate: UInt64 = 0xF006
    package static let roundTrip: UInt64 = 0x1007
    package static let proportion: UInt64 = 0x2008
    package static let powerOfTenProduct: UInt64 = 0x3009
    package static let majorUnits: UInt64 = 0x400A
    package static let amountConversion: UInt64 = 0x500B
    package static let ranges: UInt64 = 0x600C
    package static let stride: UInt64 = 0x700D
    package static let steps: UInt64 = 0x800E
    package static let minMax: UInt64 = 0x900F
    package static let exchangeRateCrossing: UInt64 = 0xA010
    package static let exchangeRateCoding: UInt64 = 0xB011
    package static let unsignedWords: UInt64 = 0xC012
    package static let signedWords: UInt64 = 0xD013
}

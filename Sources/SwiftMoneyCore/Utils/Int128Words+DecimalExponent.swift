extension Int128Words {
    /// An exponent whose power of ten an `Int128Words` can hold: `0...38`.
    package struct DecimalExponent: Equatable, Hashable, Sendable {
        /// The exponent, `0...38`.
        fileprivate let _storage: UInt8

        /// Creates an exponent, or `nil` unless `value` is `0...38`.
        ///
        /// ```swift
        /// Int128Words.DecimalExponent(exactly: 38)   // 38
        /// Int128Words.DecimalExponent(exactly: 39)   // nil
        /// ```
        ///
        /// - Parameter value: The exponent.
        /// - Returns: The exponent, or `nil` if ten to that power doesn't fit.
        package init?(exactly value: Int) {
            guard Int128Words.powersOfTen.indices.contains(value) else {
                return nil
            }

            // Truncating is exact here, `value` being a table index; the checked form measured 16
            // instructions on every `Rate` construction.
            _storage = UInt8(truncatingIfNeeded: value)
        }
    }

    /// Returns ten raised to a power.
    ///
    /// ```swift
    /// Int128Words.DecimalExponent(exactly: 20).map(Int128Words.powerOfTen)   // 10^20
    /// ```
    ///
    /// - Parameter exponent: The power to raise ten to.
    /// - Returns: `10` to the power of `exponent`.
    package static func powerOfTen(_ exponent: DecimalExponent) -> Int128Words {
        // Every entry is below 2^127, so its unsigned bits are the signed value.
        Int128Words(bitPattern: powersOfTen[Int(exponent._storage)])
    }

    // Words rather than integer literals: a table of `StaticBigInt` literals is built lazily, paying
    // a `swift_once` check on every read, while this one is initialized statically.
    /// Ten to the powers `0...38`, as words.
    private static let powersOfTen: [UInt128Words] = [
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0000_0001),   // 10^0
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0000_000A),   // 10^1
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0000_0064),   // 10^2
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0000_03E8),   // 10^3
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0000_2710),   // 10^4
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0001_86A0),   // 10^5
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_000F_4240),   // 10^6
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_0098_9680),   // 10^7
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_05F5_E100),   // 10^8
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0000_3B9A_CA00),   // 10^9
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0002_540B_E400),   // 10^10
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0017_4876_E800),   // 10^11
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_00E8_D4A5_1000),   // 10^12
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_0918_4E72_A000),   // 10^13
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0000_5AF3_107A_4000),   // 10^14
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0003_8D7E_A4C6_8000),   // 10^15
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0023_86F2_6FC1_0000),   // 10^16
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0163_4578_5D8A_0000),   // 10^17
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x0DE0_B6B3_A764_0000),   // 10^18
        UInt128Words(high: 0x0000_0000_0000_0000, low: 0x8AC7_2304_89E8_0000),   // 10^19
        UInt128Words(high: 0x0000_0000_0000_0005, low: 0x6BC7_5E2D_6310_0000),   // 10^20
        UInt128Words(high: 0x0000_0000_0000_0036, low: 0x35C9_ADC5_DEA0_0000),   // 10^21
        UInt128Words(high: 0x0000_0000_0000_021E, low: 0x19E0_C9BA_B240_0000),   // 10^22
        UInt128Words(high: 0x0000_0000_0000_152D, low: 0x02C7_E14A_F680_0000),   // 10^23
        UInt128Words(high: 0x0000_0000_0000_D3C2, low: 0x1BCE_CCED_A100_0000),   // 10^24
        UInt128Words(high: 0x0000_0000_0008_4595, low: 0x1614_0148_4A00_0000),   // 10^25
        UInt128Words(high: 0x0000_0000_0052_B7D2, low: 0xDCC8_0CD2_E400_0000),   // 10^26
        UInt128Words(high: 0x0000_0000_033B_2E3C, low: 0x9FD0_803C_E800_0000),   // 10^27
        UInt128Words(high: 0x0000_0000_204F_CE5E, low: 0x3E25_0261_1000_0000),   // 10^28
        UInt128Words(high: 0x0000_0001_431E_0FAE, low: 0x6D72_17CA_A000_0000),   // 10^29
        UInt128Words(high: 0x0000_000C_9F2C_9CD0, low: 0x4674_EDEA_4000_0000),   // 10^30
        UInt128Words(high: 0x0000_007E_37BE_2022, low: 0xC091_4B26_8000_0000),   // 10^31
        UInt128Words(high: 0x0000_04EE_2D6D_415B, low: 0x85AC_EF81_0000_0000),   // 10^32
        UInt128Words(high: 0x0000_314D_C644_8D93, low: 0x38C1_5B0A_0000_0000),   // 10^33
        UInt128Words(high: 0x0001_ED09_BEAD_87C0, low: 0x378D_8E64_0000_0000),   // 10^34
        UInt128Words(high: 0x0013_4261_72C7_4D82, low: 0x2B87_8FE8_0000_0000),   // 10^35
        UInt128Words(high: 0x00C0_97CE_7BC9_0715, low: 0xB34B_9F10_0000_0000),   // 10^36
        UInt128Words(high: 0x0785_EE10_D5DA_46D9, low: 0x00F4_36A0_0000_0000),   // 10^37
        UInt128Words(high: 0x4B3B_4CA8_5A86_C47A, low: 0x098A_2240_0000_0000),   // 10^38
    ]
}

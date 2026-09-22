/// A deterministic hash (unlike `Hasher`, which is seeded per process), so a digest is reproducible
/// across runs and platforms and can be committed and compared.
struct FNV1a {
    private(set) var value: UInt64 = 0xcbf2_9ce4_8422_2325

    mutating func combine(_ string: String) {
        for byte in string.utf8 {
            value = (value ^ UInt64(byte)) &* 0x0000_0100_0000_01b3
        }
        value = (value ^ 0x0a) &* 0x0000_0100_0000_01b3
    }
}

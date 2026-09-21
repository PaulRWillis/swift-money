import SwiftMoneyLocalization

// The packed tables' string pool: each distinct string stored once as UTF-8, with the reference that
// points at it. Sharing identical strings is most of what the packing saves, since a locale writes the
// same separators for every currency and repeats the same words across many currency names.
struct StringPool {
    private(set) var bytes: [UInt8] = []
    private var refs: [String: StringRef] = [:]

    // Where the pool begins in the finished blob, since a reference is an offset into the whole of it.
    private let base: Int

    init(base: Int) {
        self.base = base
    }

    // The reference to `string`, storing it if the pool does not hold it yet. The empty string is not
    // stored at all: a reference of no length resolves to it without reading the pool.
    mutating func insert(_ string: String) -> StringRef {
        guard !string.isEmpty else {
            return .empty
        }
        if let existing = refs[string] {
            return existing
        }

        let ref = StringRef(offset: UInt32(base + bytes.count), length: UInt32(string.utf8.count))
        bytes.append(contentsOf: string.utf8)
        refs[string] = ref

        return ref
    }
}

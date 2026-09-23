// The packed tables' run pool: a run of records stored once, with the offset it lives at. Because the
// CLDR JSON is inheritance-resolved, many locales carry byte-identical currency data, so their record
// runs are identical too; a directory entry can point at a run another locale already wrote rather than
// repeat it. This is the run-level analogue of `StringPool`.
struct RunPool {
    private var starts: [[UInt8]: Int] = [:]

    // The offset of a run holding `image`, appending it to `body` if the pool does not hold it yet.
    // An empty run stores nothing and every empty run shares one offset: a reader of no records never
    // reads the pool, so where it points does not matter.
    mutating func offset(of image: [UInt8], appendingTo body: inout BlobWriter) -> Int {
        if let existing = starts[image] {
            return existing
        }

        let start = body.offset
        body.append(image)
        starts[image] = start

        return start
    }
}

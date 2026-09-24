extension FormatMatrix {
    /// Which of `count` shards a locale belongs to, from a stable hash of its identifier.
    ///
    /// The shard depends only on the identifier and the count, never on the locale's position in the
    /// covered set, so a locale lands in the same shard however the set around it changes. The ICU
    /// deviation report relies on that: it compares a PR's output to its base one shard at a time, and
    /// the two agree on a locale's shard only because neither consults the rest of the set.
    package static func shard(ofLocale localeID: String, count: Int) -> Int {
        var hash = FNV1a()
        hash.combine(localeID)
        return Int(hash.value % UInt64(count))
    }

    /// The covered locales that fall in one shard of `count`, for splitting the deviation report across
    /// parallel CI legs. A `count` of one (or less) means no sharding, so the whole set comes back; an
    /// `index` outside `0 ..< count` yields an empty shard, which is harmless.
    package static func localeIDs(inShard index: Int, of count: Int) -> [String] {
        guard count > 1 else {
            return coveredLocaleIDs
        }

        return coveredLocaleIDs.filter { shard(ofLocale: $0, count: count) == index }
    }

    /// The covered locales named in `requested`, split into those that are covered and those that are
    /// not. Lets the deviation report audit an explicit subset, a coverage PR's new locales, instead of
    /// the whole set or a hash shard.
    ///
    /// `selected` follows the covered set's own order, so a subset run's output stays comparable to the
    /// full run's; `unknown` keeps the requested order, so a caller can report a typo or a locale that is
    /// not covered (still on the ICU fallback) as the user wrote it.
    package static func coveredLocales(among requested: [String]) -> (selected: [String], unknown: [String]) {
        let requestedSet = Set(requested)
        let coveredSet = Set(coveredLocaleIDs)

        let selected = coveredLocaleIDs.filter(requestedSet.contains)
        let unknown = requested.filter { !coveredSet.contains($0) }

        return (selected, unknown)
    }
}

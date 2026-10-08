import CLDRLocaleIdentifiers
import SwiftMoneyLocalization
import Testing

@Suite("LocaleGroup")
struct LocaleGroupTests {

    /// Real CLDR 48.2 likely-subtag entries for the languages these folders belong to.
    private static let scripts = LikelyScripts(likelySubtags: [
        "ff": "ff-Latn-SN",
        "en": "en-Latn-US",
        "sr": "sr-Cyrl-RS",
    ])

    /// A fake builder's failure, naming the folder it failed on.
    private enum BuildFailure: Error, Equatable {
        /// The folder could not be built.
        case unbuildable(String)
    }

    // MARK: - Grouping

    @Test("A folder with no script forms a group with one name")
    func scriptlessFolderStandsAlone() {
        let groups = Self.scripts.groups(of: ["en"])

        #expect(groups.map(\.shortName) == ["en"])
        #expect(groups.map { Array($0.names) } == [["en"]])
        #expect(groups.map { Array($0.folders) } == [["en"]])
    }

    @Test("A folder spelled with its implied script joins the folder without it")
    func impliedScriptJoinsTheShortFolder() {
        let groups = Self.scripts.groups(of: ["ff-Latn", "ff"])

        #expect(groups.map(\.shortName) == ["ff"])
        #expect(groups.map { Array($0.names) } == [["ff", "ff-Latn"]])
        #expect(groups.map { Array($0.folders) } == [["ff", "ff-Latn"]])
    }

    @Test("A folder with no short-named twin is named both ways")
    func loneLongFolderHasBothNames() {
        let groups = Self.scripts.groups(of: ["ff-Latn-GH"])

        #expect(groups.map(\.shortName) == ["ff-GH"])
        #expect(groups.map { Array($0.names) } == [["ff-GH", "ff-Latn-GH"]])
        #expect(groups.map { Array($0.folders) } == [["ff-Latn-GH"]])
    }

    @Test("The short name comes first even when a folder sorts before it")
    func shortNameComesFirst() {
        let groups = Self.scripts.groups(of: ["sr-Cyrl-ME"])

        #expect(groups.map(\.shortName) == ["sr-ME"])
        #expect(groups.map { Array($0.names) } == [["sr-ME", "sr-Cyrl-ME"]])
    }

    @Test("Groups come out in byte order of their short names")
    func groupsAreInByteOrder() {
        let groups = Self.scripts.groups(of: ["ff-Latn-GH", "en-GB", "ff", "en"])

        #expect(groups.map(\.shortName) == ["en", "en-GB", "ff", "ff-GH"])
    }

    @Test("A folder listed twice is grouped once")
    func repeatedFolderIsGroupedOnce() {
        let groups = Self.scripts.groups(of: ["ff", "ff-Latn", "ff"])

        #expect(groups.map { Array($0.folders) } == [["ff", "ff-Latn"]])
    }

    // MARK: - Resolving

    @Test("Folders that all build the same value resolve to it")
    func equalBuildsResolveToTheValue() throws {
        let group = try #require(Self.scripts.groups(of: ["ff", "ff-Latn"]).first)

        let resolution = group.resolve { (_: String) throws(BuildFailure) in 1 }

        #expect(resolution == .built(1))
    }

    @Test("Folders that all fail are skipped, each with its own error")
    func allFailuresAreSkippedOnePerFolder() throws {
        let group = try #require(Self.scripts.groups(of: ["ff", "ff-Latn"]).first)

        let resolution = group.resolve { (folder: String) throws(BuildFailure) -> Int in
            throw .unbuildable(folder)
        }

        guard case .skipped(let skips) = resolution else {
            Issue.record("expected .skipped, got \(resolution)")
            return
        }
        #expect(skips.map(\.folder) == ["ff", "ff-Latn"])
        #expect(skips.map(\.error) == [.unbuildable("ff"), .unbuildable("ff-Latn")])
    }

    @Test("A folder that fails after one that builds is partly built, with its failure")
    func failureAfterABuildKeepsTheFailure() throws {
        let group = try #require(Self.scripts.groups(of: ["ff", "ff-Latn"]).first)

        let resolution = group.resolve { (folder: String) throws(BuildFailure) -> Int in
            guard folder == "ff" else {
                throw .unbuildable(folder)
            }

            return 1
        }

        guard case .partlyBuilt(built: let built, failed: let failure) = resolution else {
            Issue.record("expected .partlyBuilt, got \(resolution)")
            return
        }
        #expect(built == "ff")
        #expect(failure.folder == "ff-Latn")
        #expect(failure.error == .unbuildable("ff-Latn"))
    }

    @Test("A folder that builds after one that fails is partly built, with the failure")
    func buildAfterAFailureKeepsTheFailure() throws {
        let group = try #require(Self.scripts.groups(of: ["ff", "ff-Latn"]).first)

        let resolution = group.resolve { (folder: String) throws(BuildFailure) -> Int in
            guard folder == "ff-Latn" else {
                throw .unbuildable(folder)
            }

            return 1
        }

        guard case .partlyBuilt(built: let built, failed: let failure) = resolution else {
            Issue.record("expected .partlyBuilt, got \(resolution)")
            return
        }
        #expect(built == "ff-Latn")
        #expect(failure.folder == "ff")
        #expect(failure.error == .unbuildable("ff"))
    }

    @Test("Two folders that build different values conflict")
    func differentBuildsConflict() throws {
        let group = try #require(Self.scripts.groups(of: ["ff", "ff-Latn"]).first)

        let resolution = group.resolve { (folder: String) throws(BuildFailure) in folder.count }

        #expect(resolution == .conflicting(first: "ff", second: "ff-Latn"))
    }
}

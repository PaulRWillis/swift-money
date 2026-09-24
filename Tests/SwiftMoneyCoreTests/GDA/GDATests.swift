import Foundation
import Testing

/// Checks the fixed-point engine against the General Decimal Arithmetic conformance corpus.
///
/// The corpus (`Resources/GDA`, from speleotrove.com, ICU License) is an external oracle: it proves the
/// engine's results match the standard, which the library's own hand-written tests cannot. Vectors the
/// engine cannot faithfully represent are skipped with a reason (see `GDASkipReason`); each test asserts no
/// vector failed and that enough ran to be meaningful, so a filter that quietly emptied the set would fail.
@Suite("General Decimal Arithmetic")
struct GDATests {

    @Test("Addition") func addition() throws {
        try check(files: ["add"], operations: ["add"], minimum: 400)
    }

    @Test("Subtraction") func subtraction() throws {
        try check(files: ["subtract"], operations: ["subtract"], minimum: 200)
    }

    @Test("Multiplication") func multiplication() throws {
        try check(files: ["multiply"], operations: ["multiply"], minimum: 100)
    }

    @Test("Division") func division() throws {
        try check(files: ["divide"], operations: ["divide"], minimum: 150)
    }

    @Test("Comparison") func comparison() throws {
        try check(files: ["compare"], operations: ["compare"], minimum: 300)
    }

    @Test("Minimum") func minimum() throws {
        try check(files: ["min"], operations: ["min"], minimum: 100)
    }

    @Test("Maximum") func maximum() throws {
        try check(files: ["max"], operations: ["max"], minimum: 100)
    }

    @Test("Identity (plus)") func identity() throws {
        try check(files: ["plus"], operations: ["plus"], minimum: 40)
    }

    @Test("Negation (minus)") func negation() throws {
        try check(files: ["minus"], operations: ["minus"], minimum: 40)
    }

    @Test("Absolute value") func absoluteValue() throws {
        try check(files: ["abs"], operations: ["abs"], minimum: 30)
    }

    @Test("Round to integral value, through the engine") func roundToIntegral() throws {
        try check(
            files: ["tointegral", "tointegralx"],
            operations: ["tointegral", "tointegralx"],
            minimum: 200
        )
    }

    @Test("Round to integral value, through the public API") func roundToIntegralPublicly() throws {
        try check(
            files: ["tointegral", "tointegralx"],
            operations: ["tointegral", "tointegralx"],
            minimum: 100,
            using: GDATestRunner.runPublicRounding
        )
    }

    /// Runs every vector for `operations` across `files`, records each failure, and asserts none failed and
    /// at least `minimum` ran.
    private func check(
        files: [String],
        operations: Set<String>,
        minimum: Int,
        using runner: (URL, Set<String>) throws -> GDASummary = GDATestRunner.run
    ) throws {
        var summary = GDASummary()
        for file in files {
            let url = try #require(
                Bundle.module.url(forResource: file, withExtension: "decTest", subdirectory: "Resources/GDA"),
                "missing GDA resource \(file).decTest"
            )
            summary.merge(try runner(url, operations))
        }

        print("GDA \(operations.sorted().joined(separator: ",")) — \(summary.summaryLine)")

        for failure in summary.failures {
            Issue.record("GDA vector mismatch — \(failure)")
        }
        #expect(summary.failed == 0)
        #expect(summary.passed >= minimum, "only \(summary.passed) vectors ran, expected at least \(minimum)")
    }
}

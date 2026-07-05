import Foundation
import Testing

func json(_ value: some Encodable) throws -> String {
    try #require(String(data: JSONEncoder().encode(value), encoding: .utf8))
}

func json(_ encoder: JSONEncoder, _ value: some Encodable) throws -> String {
    try #require(String(data: encoder.encode(value), encoding: .utf8))
}

/// Encodes `value` with `.sortedKeys` for deterministic key ordering in exact-match assertions.
func jsonSorted(_ encoder: JSONEncoder, _ value: some Encodable) throws -> String {
    let e = encoder
    e.outputFormatting = .sortedKeys
    return try #require(String(data: e.encode(value), encoding: .utf8))
}

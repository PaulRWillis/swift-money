import SwiftMoney

// An `Encoder` that keeps the last value it is given and does nothing else.
//
// `JSONEncoder` costs thousands of instructions, so a round trip through it hides what the money
// type contributes. This prices `encode(to:)` on its own. It is not a general encoder: it holds one
// value at a time and it has no output.
//
// Most members below are unreachable for money and record nothing. They are present because
// `KeyedEncodingContainerProtocol` requires them.
final class RecordingEncoder: Encoder {
    let codingPath: [any CodingKey] = []
    let userInfo: [CodingUserInfoKey: Any]

    var text = ""
    var integer: Int64 = 0
    var real = 0.0

    init(format: MoneyCodingFormat? = nil) {
        userInfo = format.map { [.moneyCodingFormat: $0] } ?? [:]
    }

    func container<Key: CodingKey>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> {
        KeyedEncodingContainer(RecordingKeyedContainer<Key>(encoder: self))
    }

    func singleValueContainer() -> any SingleValueEncodingContainer {
        RecordingValueContainer(encoder: self)
    }

    func unkeyedContainer() -> any UnkeyedEncodingContainer {
        preconditionFailure("Money never asks for an unkeyed container")
    }
}

private struct RecordingValueContainer: SingleValueEncodingContainer {
    let encoder: RecordingEncoder
    var codingPath: [any CodingKey] { [] }

    mutating func encode(_ value: String) throws { encoder.text = value }
    mutating func encode(_ value: Int64) throws { encoder.integer = value }
    mutating func encode(_ value: Double) throws { encoder.real = value }
    mutating func encode(_ value: some Encodable) throws { try value.encode(to: encoder) }

    mutating func encodeNil() throws {}
    mutating func encode(_: Bool) throws {}
    mutating func encode(_: Float) throws {}
    mutating func encode(_: Int) throws {}
    mutating func encode(_: Int8) throws {}
    mutating func encode(_: Int16) throws {}
    mutating func encode(_: Int32) throws {}
    mutating func encode(_: UInt) throws {}
    mutating func encode(_: UInt8) throws {}
    mutating func encode(_: UInt16) throws {}
    mutating func encode(_: UInt32) throws {}
    mutating func encode(_: UInt64) throws {}
}

private struct RecordingKeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: RecordingEncoder
    var codingPath: [any CodingKey] { [] }

    mutating func encode(_ value: String, forKey _: Key) throws { encoder.text = value }
    mutating func encode(_ value: Int64, forKey _: Key) throws { encoder.integer = value }
    mutating func encode(_ value: Double, forKey _: Key) throws { encoder.real = value }
    mutating func encode(_ value: some Encodable, forKey _: Key) throws { try value.encode(to: encoder) }

    mutating func encodeNil(forKey _: Key) throws {}
    mutating func encode(_: Bool, forKey _: Key) throws {}
    mutating func encode(_: Float, forKey _: Key) throws {}
    mutating func encode(_: Int, forKey _: Key) throws {}
    mutating func encode(_: Int8, forKey _: Key) throws {}
    mutating func encode(_: Int16, forKey _: Key) throws {}
    mutating func encode(_: Int32, forKey _: Key) throws {}
    mutating func encode(_: UInt, forKey _: Key) throws {}
    mutating func encode(_: UInt8, forKey _: Key) throws {}
    mutating func encode(_: UInt16, forKey _: Key) throws {}
    mutating func encode(_: UInt32, forKey _: Key) throws {}
    mutating func encode(_: UInt64, forKey _: Key) throws {}

    mutating func nestedContainer<Nested: CodingKey>(
        keyedBy _: Nested.Type,
        forKey _: Key
    ) -> KeyedEncodingContainer<Nested> {
        preconditionFailure("Money never asks for a nested container")
    }

    mutating func nestedUnkeyedContainer(forKey _: Key) -> any UnkeyedEncodingContainer {
        preconditionFailure("Money never asks for a nested unkeyed container")
    }

    mutating func superEncoder() -> any Encoder { encoder }
    mutating func superEncoder(forKey _: Key) -> any Encoder { encoder }
}

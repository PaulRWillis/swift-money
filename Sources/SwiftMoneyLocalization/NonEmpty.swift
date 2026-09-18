/// A sequence that always has at least one element.
///
/// ```swift
/// NonEmpty([1, 2])     // a value
/// NonEmpty<Int>([])    // nil
/// ```
package struct NonEmpty<Element> {
    package let first: Element

    private let rest: [Element]

    /// Creates a sequence from its first element and any that follow it.
    package init(_ first: Element, _ rest: [Element] = []) {
        self.first = first
        self.rest = rest
    }

    /// Creates a sequence from an array.
    ///
    /// - Returns: `nil` if `elements` is empty.
    package init?(_ elements: [Element]) {
        guard let first = elements.first else {
            return nil
        }

        self.init(first, Array(elements.dropFirst()))
    }
}

extension NonEmpty: Sequence {
    package func makeIterator() -> Iterator {
        Iterator(elements: self)
    }

    package struct Iterator: IteratorProtocol {
        private let elements: NonEmpty
        private var offset = 0

        fileprivate init(elements: NonEmpty) {
            self.elements = elements
        }

        package mutating func next() -> Element? {
            defer { offset += 1 }

            guard offset > 0 else {
                return elements.first
            }

            let index = offset - 1
            return index < elements.rest.count ? elements.rest[index] : nil
        }
    }
}

extension NonEmpty: Equatable where Element: Equatable {}

extension NonEmpty: Sendable where Element: Sendable {}

import Foundation
import SwiftMoneyLocalization

public extension NumberingSystem {
    /// Creates a numbering system from a Foundation one, or `nil` when the engine does not model it.
    ///
    /// Lives here rather than in `SwiftMoneyLocalization` so that module stays free of Foundation. A `nil`
    /// result (an algorithmic system, `hanidec`, or anything the engine cannot render) tells the bridge to
    /// fall back to ICU rather than emit the locale's default digits.
    ///
    /// - Parameter foundation: A Foundation numbering system, e.g. `locale.numberingSystem`.
    init?(_ foundation: Locale.NumberingSystem) {
        self.init(foundation.identifier)
    }
}

// The all-in-one umbrella. `import SwiftMoney` re-exports the core money types and the Foundation-backed
// formatting, localized parsing, `Decimal` interop and JSON configuration together, so a caller writes
// one import instead of importing `SwiftMoneyCore` and `SwiftMoneyFoundation` separately.
//
// Embedded targets import `SwiftMoneyCore` directly instead: this umbrella re-exports
// `SwiftMoneyFoundation`, which pulls in Foundation, and Foundation is not available under Embedded Swift.
//
// `@_exported` is an underscored (unofficial) attribute, but it is the standard — and only — mechanism for
// re-exporting a module's whole API under an umbrella import. The choice is deliberate; the fallback, were
// it ever removed, is a plain product that groups the two targets and leaves callers writing two imports.
@_exported import SwiftMoneyCore
@_exported import SwiftMoneyLocalization
@_exported import SwiftMoneyFoundation

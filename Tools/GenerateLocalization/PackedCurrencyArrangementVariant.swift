// One locale's currency-arrangement variant row: the interned indices its accounting, letter-adjacent
// and accounting+letter-adjacent presentations resolve to, when at least one differs from the locale's
// standard arrangement. An index equal to the locale's own `standardArrangementIndex` means "no variant"
// for that cell. Laid out sorted by localeIndex so the runtime finds a row by binary search.
struct PackedCurrencyArrangementVariant {
    let localeIndex: UInt16
    let accountingArrangementIndex: UInt16
    let alphaArrangementIndex: UInt16
    let alphaAccountingArrangementIndex: UInt16
}

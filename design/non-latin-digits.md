# PR 6 — render currency amounts in a locale's own digit set

> **BUILT on branch `feat/non-latin-digits`, awaiting review.** This is the design as approved
> (Paul, 2026-09-23), kept as the record. Two things shipped differently from the original plan and
> are worth knowing before reading on.
>
> - **`DigitGlyphs` holds one scalar, not ten glyph strings.** The plan left storage to settle during
>   coding against the engine benchmark. A heap-backed `[String]` made the ASCII fast path pay ARC on
>   every format; a trivial value type does not. A numbering system's ten digits are ten consecutive
>   Unicode scalars, so the set is captured by its first scalar plus a width.
> - **The Latin fast path costs ~26 more instructions** (1159 → 1185, malloc still 0). Reading the
>   digit set in the hot `format` cannot be made free without splitting `format` into separate ASCII
>   and glyph render paths. Paul accepted the +26 rather than duplicate the writers (2026-09-24).

**Written for: the agent picking up the wide-locale-coverage programme.** Self-contained.

---

## 1. What this changes and why

The engine wrote ASCII digits `0`–`9` only, so the generator skipped every locale whose default
numbering system was not `latn` — 84 locales that write amounts in Arabic-Indic, Devanagari, Bengali,
Adlam and other digit sets. This PR teaches the engine to render a locale's own digit set and the
generator to read it, lifting the non-Latin-digit skip.

This is item 6 of the wide-locale-coverage programme. Coverage rises from **544 to 586 of 766**
locales. The remaining non-Latin-digit locales stay deferred for reasons the existing gates already
catch once the digit skip is lifted: a directional mark in the pattern (21 arab + 1 arabext), a
non-Latin-script negative subpattern (PR 5's Latin-script gate), or an algorithmic numbering system
with no digit glyphs.

## 2. The type-safe design

Two Core types, one file each:

- **`DigitGlyphs`** — the ten glyphs a locale writes `0`–`9` with. A numbering system's digits are ten
  consecutive scalars of one UTF-8 width, so the value is `zero: Unicode.Scalar` plus `bytesPerDigit`.
  `init?(_:)` is the only construction path: it rejects anything that is not ten consecutive same-width
  scalars, which is what keeps a non-contiguous set (only `hanidec` in CLDR) or an algorithmic system
  out. The type is trivial (no heap reference), so a `MoneyFormat` carrying the default ASCII set pays
  nothing to store or read it.
- **`Digits`** — `.ascii` or `.glyphs(DigitGlyphs)`. `.ascii` is a named case, not the absence of a
  set, so the common path is a plain byte write and never a lookup.

`MoneyFormat` gains `digits: Digits` (default `.ascii`). The generator emits an empty digit-glyph
string for a `latn` locale, which decodes back to `.ascii`, so every Latin record is byte-identical to
before and the golden digests do not move on the model change alone.

## 3. The engine

Four digit-encoding sites switch on the digit set: the two byte-buffer writers (`writeGroupedWhole`,
`writeDigits`) go through `writeDigit`, which writes a plain ASCII byte or encodes the glyph's scalar
as UTF-8; the two run-seam builders (`appendInteger`, `digitsString`) append an ASCII character or the
glyph's scalar. The output buffer is sized as the digit count times `bytesPerDigit` (one, for ASCII),
because a non-ASCII glyph is wider than a byte and under-allocating would corrupt the buffer.

### The fast-path cost

The en_GB raw-engine benchmark is the load-bearing gate: 1159 instructions / 0 malloc on `main`.
Every structure tried — per-digit switch, resolve-once, a two-loop hoist, heap vs trivial storage —
lands between 1179 and 1209, because the hot `format` must read the digit set to size the buffer and
choose the write. The minimum is ~1185 (+26, +2.2%), malloc still 0. Reaching exactly 1159 needs
`format` split into separate ASCII and glyph paths (four near-duplicate writers with the grouping
logic duplicated). Paul chose the +26 over the duplication.

## 4. The generator

`tables(for:)` reads the separators, pattern and digit glyphs from the locale's **default numbering
system** rather than always from `latn`, falling back to `latn` per key only where the system's own
block is absent. The digit glyphs come from `numberingSystems.json` (numeric systems only). A `latn`
locale emits no digit set; a representable non-Latin system emits its ten glyphs; anything else is
refused as `.nonLatinDigits`.

The `.nonLatinDigits` trigger moved out of `UnsupportedNumberFormat.init` (which no longer takes the
numbering system) to where the digit set is resolved, so representability is decided against the
digit-set data by one path shared with the decoder. The directional-mark and grouping-threshold checks
now run on the default system's pattern — the one the locale actually renders with — so a marked
non-Latin locale is still deferred.

## 5. The proof: the ICU audit

Goldens lock output against itself, so they cannot say the new locales are *right* — only the ICU
deviation report can (see the `run-the-icu-audit-before-trusting-coverage` lesson from PR 4). Sharded
across 8 legs, filtered to the 42 new locales:

- **22 of the 42 have zero deviations** — the platform ICU renders them identically, native digits and
  all, across Devanagari (`ne`), Adlam (`ff-Adlm-*`), N'Ko (`nqo`), Ol Chiki (`sat`) and more. An
  exact match is the strongest structural check there is.
- **The other 20 deviate only in the digit system**: the engine writes CLDR 48.2's native digits (and
  CLDR's own `minusSign`, which for the `arabext` locales carries left-to-right marks), where the
  platform ICU is stale and writes ASCII. Every such deviation is from ICU, never from CLDR, which is
  the bar Paul set.

No new-locale deviation is structural. The 544 previously-covered locales are untouched: their golden
digests are byte-identical, only 42 entries added.

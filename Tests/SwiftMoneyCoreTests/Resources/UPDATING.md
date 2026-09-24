# Updating the GDA conformance corpus

The `GDA/` directory holds a subset of the General Decimal Arithmetic test suite
(Mike Cowlishaw / IBM, <https://speleotrove.com/decimal/>), used under the ICU
License (`GDA/LICENSE`). The `GDATests` suite parses these files at runtime and
checks the library's arithmetic and rounding against them.

## Refreshing

Currently vendored: **version 2.62**.

1. Download and extract:

   ```
   curl -O https://speleotrove.com/decimal/dectest.zip
   unzip -o dectest.zip -d dectest
   ```

2. Copy the files we use into `GDA/` (only these, to keep the checkout small):

   ```
   cd dectest
   cp tointegral.decTest tointegralx.decTest \
      add.decTest subtract.decTest multiply.decTest divide.decTest \
      compare.decTest min.decTest max.decTest plus.decTest minus.decTest abs.decTest \
      ../Tests/SwiftMoneyCoreTests/Resources/GDA/
   ```

3. Confirm the `version:` directive at the top of each file matches, and update the
   number above.

4. Run `swift test --filter GDA` and review the skip counts printed per operation;
   new cases outside the engine's representable range or supported rounding modes are
   skipped, not failed.

## What is and isn't run

- **Rounding:** `tointegral` / `tointegralx` drive the six supported rounding rules,
  both through the fixed-point engine and through the public money API. Vectors tagged
  `rounding: half_down` or `05up` are skipped (the library has no such mode).
- **Arithmetic:** `add`, `subtract`, `multiply`, `divide`, `compare`, `min`, `max`,
  `plus`, `minus`, `abs`. Only vectors whose result the corpus did not round (no
  `Inexact` or `Rounded` condition) are checked: the fixed-point engine keeps 18
  fractional digits rather than rounding to a decimal significance, so a rounded
  corpus result would legitimately differ. This drops most `multiply`/`divide` cases.
- Vectors whose operands exceed the engine's range or fractional-digit capacity, or
  that expect a trap (overflow, division by zero, invalid operation), are skipped.

# CI outputs

This orphan branch holds files that CI regenerates, so those commits never land on `main`:

- `coverage.svg`: the coverage badge, pushed by `swift-code-coverage.yml`.
- `BENCHMARKS.md`: benchmark results, pushed by `swift-benchmark-update.yml`.

Do not edit these by hand. The next CI run overwrites them.

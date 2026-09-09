# Validation record

Validated locally on 2026-09-09 with:

```text
moon 0.1.20260827 (d0aaa07 2026-08-27)
```

## Results

| Check | Result |
| --- | --- |
| `moon fmt --check` | passed |
| `moon check` | passed |
| `moon test` | 109 test groups passed, 0 failed |
| `moon run cmd/main` | produced the expected GitHub API URL |
| `moon info` | generated package interfaces |
| MoonBit source | 4,061 lines (2,604 implementation + 1,457 tests) |
| library coverage | 1,062/1,117 expressions (95.1%) |

Example output:

```text
https://api.github.com/repos/moonbitlang/core/issues?labels=good%20first%20issue&labels=help%20wanted
```

The commands were run from a clean source tree with no third-party package
dependencies. The downloaded compiler and standard library are stored under
the ignored `work/` directory and are not part of the project deliverable.

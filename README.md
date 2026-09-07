# uritemplate.mbt

A dependency-free [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) URI
Template expander written in MoonBit.

This project is being developed for the September 2026 MoonBit Hackathon. The
initial release focuses on a small, reusable networking primitive with a clear
standard and reproducible conformance tests.

## Planned scope

- Level 1: simple string expansion
- Level 2: reserved and fragment expansion
- Level 3: path, query and continuation operators
- Level 4: prefix modifiers and composite value explosion
- UTF-8 percent encoding
- Structured expansion errors
- RFC 6570 examples as executable tests

## Status

Initial project scaffold. Implementation and examples will be added through
separate, traceable commits.

## Development

```console
moon check
moon test
moon fmt --check
```

## License and references

This is an original MoonBit implementation based on the behavior specified by
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570). The RFC examples are used
as interoperability test vectors. The source code is licensed under
Apache-2.0.


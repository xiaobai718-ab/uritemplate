# Changelog

All notable changes to this project are documented here.

## Unreleased

- Add RFC 3986 URI parsing, relative-reference resolution, normalization,
  origin comparison, component access, and safe modification.
- Add percent decoding and ordered query parameter parsing and rendering.
- Add fluent URI and URI Template builders.
- Add route matching/rendering and configurable URI validation policies.
- Expand validation to 109 test groups, including official RFC vectors.
- Add a reusable `Template` API that parses and validates expressions once.
- Preserve valid percent-encoded triplets during reserved and fragment
  expansion, as required by RFC 6570.

## 0.1.0 - 2026-09-07

- Implement RFC 6570 Level 1–4 URI Template expansion.
- Support scalar, list, and associative values.
- Add UTF-8 percent encoding and reserved expansion.
- Add structured errors for malformed templates and modifiers.
- Add conformance tests based on RFC 6570 examples.

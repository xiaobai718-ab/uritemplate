# Changelog

All notable changes to this project are documented here.

## Unreleased

- Add a reusable `Template` API that parses and validates expressions once.
- Preserve valid percent-encoded triplets during reserved and fragment
  expansion, as required by RFC 6570.

## 0.1.0 - 2026-09-07

- Implement RFC 6570 Level 1–4 URI Template expansion.
- Support scalar, list, and associative values.
- Add UTF-8 percent encoding and reserved expansion.
- Add structured errors for malformed templates and modifiers.
- Add conformance tests based on RFC 6570 examples.

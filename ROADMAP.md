# Project roadmap

`uritemplate.mbt` is a MoonBit toolkit for URI Templates and URI processing.
The implementation is original MoonBit code guided by RFC 6570 and RFC 3986.

## Completed

- RFC 6570 Level 1–4 expansion for scalar, list, and associative values
- Parsed templates, variable inspection, checked expansion, and template builder
- RFC 3986 URI-reference parsing, serialization, normalization, and resolution
- UTF-8 percent codec and ordered query parameter multi-map
- URI builder, route matcher, path helpers, and configurable URI policy
- Offline RFC conformance vectors and cross-target type checking
- 4,061 lines of MoonBit with 109 passing test groups and 95.1% coverage

## Version 0.1.0

- Review the public API naming and generated package interface
- Publish the package to Mooncakes
- Create a signed GitHub release with reproducible validation instructions
- Add a command-line demonstration for expansion, parsing, and resolution

## Later work

- Import additional official negative and extended URI Template vectors
- Add benchmarks for parsed-template reuse and large query collections
- Document browser, server, SDK generator, and routing integrations
- Evaluate internationalized host-name support without weakening RFC behavior

Progress is recorded through focused commits and `CHANGELOG.md`. New features
should include tests and remain free of third-party runtime dependencies.

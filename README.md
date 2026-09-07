# uritemplate.mbt

A dependency-free [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) URI
Template expander written in MoonBit.

This project was created for the September 2026 MoonBit Hackathon. It focuses
on a small, reusable networking primitive with a clear standard and
reproducible conformance tests.

## Features

- RFC 6570 Level 1–4 expansion
- All standard operators: `+`, `#`, `.`, `/`, `;`, `?`, and `&`
- Scalar, list, and associative values
- Prefix modifiers such as `{name:8}`
- Explode modifiers such as `{?tags*}` and `{?params*}`
- UTF-8 percent encoding based on RFC 3986
- Omission of undefined and empty composite values
- Structured syntax errors
- No third-party runtime dependencies

## Example

```moonbit
test "build an API URL" {
  let values = @uritemplate.Bindings::new()
    .set_string("owner", "moonbitlang")
    .set_string("repo", "core")
    .set_list("labels", ["good first issue", "help wanted"])

  let url = @uritemplate.expand(
    "https://api.github.com/repos{/owner,repo}/issues{?labels*}",
    values,
  ) catch {
    _ => abort("invalid URI template")
  }

  inspect(
    url,
    content=(
      #|https://api.github.com/repos/moonbitlang/core/issues?labels=good%20first%20issue&labels=help%20wanted
    ),
  )
}
```

Add the package to a MoonBit project after it is published:

```console
moon add your-github-id/uritemplate
```

Then import it in `moon.pkg`:

```moonbit
import {
  "your-github-id/uritemplate",
}
```

## API

`Bindings` uses chainable setters:

```moonbit
let values = @uritemplate.Bindings::new()
  .set_string("name", "MoonBit")
  .set_list("colors", ["red", "green"])
  .set_assoc("point", [("x", "10"), ("y", "20")])
```

`expand(template, values)` returns the expanded string or raises an
`ExpandError`. `encode(value, allow_reserved=false)` is also public for callers
that need RFC 3986 component encoding directly.

## Conformance scope

The implementation covers the RFC 6570 expansion levels and operators used by
the RFC examples. Variable names accept ASCII letters, digits, `_`, `.`, and
percent signs. Values are Unicode strings and are encoded as UTF-8. Prefix
length is counted in Unicode scalar values.

The library expands templates; it does not parse an already expanded URI or
validate its scheme and host. Associative input uses an array of pairs so its
output order is deterministic.

## Development

```console
moon check
moon test
moon fmt --check
moon info
```

The test suite includes simple, reserved, fragment, label, path, matrix, query,
continuation, prefix, list, associative, Unicode, undefined-value, empty-value,
and malformed-template cases.

## License and references

This is an original MoonBit implementation based on the behavior specified by
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570). The RFC examples are used
as interoperability test vectors. The source code is licensed under
Apache-2.0.

See [PROJECT_PROPOSAL.md](PROJECT_PROPOSAL.md) for the hackathon scope and
acceptance plan.

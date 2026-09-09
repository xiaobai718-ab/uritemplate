# uritemplate.mbt

A MoonBit toolkit for [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) URI
Templates and [RFC 3986](https://www.rfc-editor.org/rfc/rfc3986) URI handling.

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
- Reusable parsed templates for repeated expansion
- RFC 3986 URI-reference parsing, normalization, resolution, and comparison
- Ordered query parameter parsing and form/RFC 3986 encoding
- Fluent URI and URI Template builders
- Route matching, capture decoding, and route rendering
- Configurable URI validation policies
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
moon add xiaobai718-ab/uritemplate
```

Then import it in `moon.pkg`:

```moonbit
import {
  "xiaobai718-ab/uritemplate",
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

For a template used many times, parse and validate it once:

```moonbit
let template = @uritemplate.Template::parse("/users{/id}{?view}") catch {
  _ => abort("invalid template")
}
let url = template.expand(
  @uritemplate.Bindings::new()
    .set_string("id", "42")
    .set_string("view", "full"),
)
```

Parse and resolve relative URI references:

```moonbit
let absolute = @uritemplate.resolve_uri(
  "https://example.com/docs/guide/",
  "../api/index.html?q=MoonBit",
) catch {
  _ => abort("invalid URI")
}
```

Build a URI without allowing user data to introduce delimiters:

```moonbit
let url = @uritemplate.UriBuilder::new("https", "api.example.com")
  .push_path("users")
  .push_path("刘明杰")
  .add_query("view", "full details")
  .to_string()
```

Additional public APIs include `QueryParams`, `RoutePattern`, `UriPolicy`,
`TemplateBuilder`, `percent_decode`, `normalize_uri`, and `equivalent_uri`.

## Project structure

MoonBit treats the files in the repository root as one library package. Each
implementation module has a neighboring `_test.mbt` file so its behavior is
easy to locate and review.

| Area | Implementation | Tests |
| --- | --- | --- |
| URI Template expansion | `uritemplate.mbt` | `uritemplate_test.mbt`, `rfc6570_conformance_test.mbt` |
| Template inspection and construction | `template_tools.mbt`, `template_builder.mbt` | matching `_test.mbt` files |
| URI parsing and components | `uri.mbt`, `components.mbt` | matching `_test.mbt` files |
| URI normalization and policy | `normalize.mbt`, `policy.mbt` | matching `_test.mbt` files |
| Encoding and query parameters | `percent.mbt`, `query.mbt` | matching `_test.mbt` files |
| URI and route construction | `builder.mbt`, `route.mbt` | matching `_test.mbt` files |
| Runnable example | `cmd/main/` | exercised by `moon run cmd/main` |
| Automation and project metadata | `.github/workflows/`, `moon.mod`, `moon.pkg` | CI and package configuration |

Supporting documents are kept at the root so GitHub and package registries can
discover them directly: `CHANGELOG.md`, `CONTRIBUTING.md`, `VALIDATION.md`,
`ROADMAP.md`, and `LICENSE`.

## Conformance scope

The implementation covers the RFC 6570 expansion levels and operators used by
the RFC examples. Variable names accept ASCII letters, digits, `_`, `.`, and
percent signs. Values are Unicode strings and are encoded as UTF-8. Prefix
length is counted in Unicode scalar values.

The URI parser preserves components rather than applying browser-specific URL
rules. `UriPolicy` provides application-level restrictions for schemes,
authority, ports, user information, fragments, and input length. Associative
template input uses an array of pairs so output order is deterministic.

## Development

```console
moon check
moon test
moon fmt --check
moon info
```

The test suite includes the official RFC 6570 examples, RFC 3986 reference
resolution vectors, URI parsing and normalization, percent codecs, query
multi-maps, builders, routes, policies, Unicode, and malformed input.

## License and references

This is an original MoonBit implementation based on the behavior specified by
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) and
[RFC 3986](https://www.rfc-editor.org/rfc/rfc3986). The RFC examples and the
Apache-2.0 [URI Template test suite](https://github.com/uri-templates/uritemplate-test)
are used as interoperability vectors. The source code is licensed under Apache-2.0.

See [ROADMAP.md](ROADMAP.md) for completed milestones and planned releases.

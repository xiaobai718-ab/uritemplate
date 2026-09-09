///|
test "normalize scheme and host case" {
  inspect(normalize_uri("HTTP://Example.COM/a"), content="http://example.com/a")
}

///|
test "remove well-known default ports" {
  inspect(
    normalize_uri("http://example.com:80/"),
    content="http://example.com/",
  )
  inspect(
    normalize_uri("https://example.com:443/"),
    content="https://example.com/",
  )
  inspect(normalize_uri("ws://example.com:80/"), content="ws://example.com/")
  inspect(normalize_uri("wss://example.com:443/"), content="wss://example.com/")
  inspect(normalize_uri("ftp://example.com:21/"), content="ftp://example.com/")
  inspect(
    normalize_uri("https://example.com:8443/"),
    content="https://example.com:8443/",
  )
}

///|
test "normalize percent escape spelling" {
  inspect(
    normalize_uri("https://example.com/%7euser/%e4%bd%a0?q=%41%2f"),
    content="https://example.com/~user/%E4%BD%A0?q=A%2F",
  )
}

///|
test "normalize dot segments in URI path" {
  inspect(
    normalize_uri("https://example.com/a/b/../c/./d"),
    content="https://example.com/a/c/d",
  )
}

///|
test "compare normalized URI equivalence" {
  inspect(
    equivalent_uri(
      "HTTP://EXAMPLE.COM:80/a/../b/%7Euser", "http://example.com/b/~user",
    ),
    content="true",
  )
  inspect(
    equivalent_uri("https://example.com/a", "https://example.com/b"),
    content="false",
  )
}

///|
test "same origin accounts for case and default ports" {
  let one = UriReference::parse("HTTPS://Example.COM:443/a")
  let two = UriReference::parse("https://example.com/b?q=1")
  let three = UriReference::parse("https://example.com:8443/a")
  inspect(one.same_origin(two), content="true")
  inspect(one.same_origin(three), content="false")
  assert_eq(one.origin(), Some(("https", "example.com", None)))
}

///|
test "relative references have no origin" {
  let relative = UriReference::parse("a/b")
  assert_eq(relative.origin(), None)
  inspect(relative.same_origin(relative), content="false")
}

///|
test "modify fragment without reparsing" {
  let uri = UriReference::parse("https://example.com/a?q=1#old")
  inspect(
    uri.without_fragment().to_string(),
    content="https://example.com/a?q=1",
  )
  inspect(
    uri.with_fragment(Some("new")).to_string(),
    content="https://example.com/a?q=1#new",
  )
  inspect(
    uri.with_fragment(Some("")).to_string(),
    content="https://example.com/a?q=1#",
  )
}

///|
test "read and replace URI query parameters" {
  let uri = UriReference::parse(
    "https://example.com/search?q=MoonBit&page=1#top",
  )
  let params = uri.query_params()
  assert_eq(params.get("q"), Some("MoonBit"))
  let changed = params.set("page", "2").add("tag", "uri")
  inspect(
    uri.with_query_params(changed).to_string(),
    content="https://example.com/search?q=MoonBit&page=2&tag=uri#top",
  )
  inspect(
    uri.with_query_params(QueryParams::new()).to_string(),
    content="https://example.com/search#top",
  )
}

///|
test "access raw and decoded path segments" {
  let uri = UriReference::parse("https://example.com/users/%E5%88%98/a%2Fb")
  assert_eq(uri.path_segments(), ["users", "%E5%88%98", "a%2Fb"])
  assert_eq(uri.decoded_path_segments(), ["users", "刘", "a/b"])
}

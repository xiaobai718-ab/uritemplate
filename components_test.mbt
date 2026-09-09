///|
test "inspect filename and extension" {
  let uri = UriReference::parse("https://example.com/docs/api/index.html?q=1")
  assert_eq(uri.filename(), Some("index.html"))
  assert_eq(uri.extension(), Some("html"))
  assert_eq(UriReference::parse("https://example.com/").filename(), None)
  assert_eq(UriReference::parse("/README").extension(), None)
  assert_eq(UriReference::parse("/.gitignore").extension(), None)
  assert_eq(UriReference::parse("/file.").extension(), None)
}

///|
test "derive effective ports" {
  assert_eq(
    UriReference::parse("http://example.com/").effective_port(),
    Some(80),
  )
  assert_eq(
    UriReference::parse("https://example.com/").effective_port(),
    Some(443),
  )
  assert_eq(
    UriReference::parse("ftp://example.com/").effective_port(),
    Some(21),
  )
  assert_eq(
    UriReference::parse("https://example.com:8443/").effective_port(),
    Some(8443),
  )
  assert_eq(UriReference::parse("custom://example.com/").effective_port(), None)
}

///|
test "identify secure transport schemes" {
  inspect(
    UriReference::parse("HTTPS://example.com/").is_secure_transport(),
    content="true",
  )
  inspect(
    UriReference::parse("wss://example.com/").is_secure_transport(),
    content="true",
  )
  inspect(
    UriReference::parse("http://example.com/").is_secure_transport(),
    content="false",
  )
}

///|
test "replace and append URI path" {
  let uri = UriReference::parse("https://example.com/api?q=1#top")
  inspect(
    uri.with_path("/v2/users").to_string(),
    content="https://example.com/v2/users?q=1#top",
  )
  inspect(
    uri.append_path_segment("a/b").to_string(),
    content="https://example.com/api/a%2Fb?q=1#top",
  )
  inspect(
    UriReference::parse("https://example.com")
    .append_path_segment("first")
    .to_string(),
    content="https://example.com/first",
  )
}

///|
test "derive parent URI" {
  inspect(
    UriReference::parse("https://example.com/a/b/c?q=1#top")
    .parent()
    .to_string(),
    content="https://example.com/a/b",
  )
  inspect(
    UriReference::parse("https://example.com/a").parent().to_string(),
    content="https://example.com/",
  )
  inspect(
    UriReference::parse("relative/file.txt").parent().to_string(),
    content="relative",
  )
}

///|
test "parse absolute URI components" {
  let uri = UriReference::parse(
    "https://user@example.com:8443/a/b?mode=full#section",
  )
  assert_eq(uri.scheme(), Some("https"))
  inspect(uri.path(), content="/a/b")
  assert_eq(uri.query(), Some("mode=full"))
  assert_eq(uri.fragment(), Some("section"))
  inspect(uri.is_absolute(), content="true")
  inspect(uri.has_authority(), content="true")
  match uri.authority() {
    Some(authority) => {
      assert_eq(authority.userinfo(), Some("user"))
      inspect(authority.host(), content="example.com")
      assert_eq(authority.port(), Some(8443))
      inspect(authority.to_string(), content="user@example.com:8443")
    }
    None => fail("expected authority")
  }
  inspect(
    uri.to_string(),
    content="https://user@example.com:8443/a/b?mode=full#section",
  )
}

///|
test "parse IPv6 authority" {
  let uri = UriReference::parse("http://[2001:db8::1]:8080/index")
  match uri.authority() {
    Some(authority) => {
      inspect(authority.host(), content="[2001:db8::1]")
      assert_eq(authority.port(), Some(8080))
    }
    None => fail("expected authority")
  }
}

///|
test "parse relative references" {
  let relative = UriReference::parse("../images/logo.svg?dark=1#top")
  assert_eq(relative.scheme(), None)
  assert_eq(relative.authority(), None)
  inspect(relative.path(), content="../images/logo.svg")
  assert_eq(relative.query(), Some("dark=1"))
  assert_eq(relative.fragment(), Some("top"))
  inspect(relative.is_absolute(), content="false")
  inspect(relative.to_string(), content="../images/logo.svg?dark=1#top")
}

///|
test "parse empty query and fragment" {
  let uri = UriReference::parse("https://example.com/path?#")
  assert_eq(uri.query(), Some(""))
  assert_eq(uri.fragment(), Some(""))
  inspect(uri.to_string(), content="https://example.com/path?#")
}

///|
test "reject malformed schemes" {
  try UriReference::parse("1http:value") catch {
    InvalidScheme("1http") => ()
    _ => fail("expected InvalidScheme")
  } noraise {
    _ => fail("expected parsing to fail")
  }
  try UriReference::parse("ht_tp:value") catch {
    InvalidScheme("ht_tp") => ()
    _ => fail("expected InvalidScheme")
  } noraise {
    _ => fail("expected parsing to fail")
  }
}

///|
test "reject malformed authorities and ports" {
  try UriReference::parse("http://example.com:abc/") catch {
    InvalidPort("abc") => ()
    _ => fail("expected InvalidPort")
  } noraise {
    _ => fail("expected parsing to fail")
  }
  try UriReference::parse("http://example.com:70000/") catch {
    InvalidPort("70000") => ()
    _ => fail("expected InvalidPort")
  } noraise {
    _ => fail("expected parsing to fail")
  }
  try UriReference::parse("http://[2001:db8::1/path") catch {
    InvalidAuthority(_) => ()
    _ => fail("expected InvalidAuthority")
  } noraise {
    _ => fail("expected parsing to fail")
  }
}

///|
test "normalize dot segments" {
  inspect(normalize_path("/a/b/./c/../d"), content="/a/b/d")
  inspect(normalize_path("a/b/../../c"), content="c")
  inspect(normalize_path("/../a"), content="/a")
  inspect(normalize_path("/a/b/.."), content="/a/")
  inspect(normalize_path("/a/./"), content="/a/")
  inspect(normalize_path("/"), content="/")
  inspect(normalize_path(""), content="")
}

///|
test "RFC 3986 normal resolution examples" {
  let base = "http://a/b/c/d;p?q"
  let cases : Array[(String, String)] = [
    ("g:h", "g:h"),
    ("g", "http://a/b/c/g"),
    ("./g", "http://a/b/c/g"),
    ("g/", "http://a/b/c/g/"),
    ("/g", "http://a/g"),
    ("//g", "http://g"),
    ("?y", "http://a/b/c/d;p?y"),
    ("g?y", "http://a/b/c/g?y"),
    ("#s", "http://a/b/c/d;p?q#s"),
    ("g#s", "http://a/b/c/g#s"),
    ("g?y#s", "http://a/b/c/g?y#s"),
    (";x", "http://a/b/c/;x"),
    ("g;x", "http://a/b/c/g;x"),
    ("g;x?y#s", "http://a/b/c/g;x?y#s"),
    ("", "http://a/b/c/d;p?q"),
    (".", "http://a/b/c/"),
    ("./", "http://a/b/c/"),
    ("..", "http://a/b/"),
    ("../", "http://a/b/"),
    ("../g", "http://a/b/g"),
    ("../..", "http://a/"),
    ("../../", "http://a/"),
    ("../../g", "http://a/g"),
  ]
  for item in cases {
    let (reference, expected) = item
    inspect(resolve_uri(base, reference), content=expected)
  }
}

///|
test "RFC 3986 abnormal resolution examples" {
  let base = "http://a/b/c/d;p?q"
  let cases : Array[(String, String)] = [
    ("../../../g", "http://a/g"),
    ("../../../../g", "http://a/g"),
    ("/./g", "http://a/g"),
    ("/../g", "http://a/g"),
    ("g.", "http://a/b/c/g."),
    (".g", "http://a/b/c/.g"),
    ("g..", "http://a/b/c/g.."),
    ("..g", "http://a/b/c/..g"),
    ("./../g", "http://a/b/g"),
    ("./g/.", "http://a/b/c/g/"),
    ("g/./h", "http://a/b/c/g/h"),
    ("g/../h", "http://a/b/c/h"),
    ("g;x=1/./y", "http://a/b/c/g;x=1/y"),
    ("g;x=1/../y", "http://a/b/c/y"),
    ("g?y/./x", "http://a/b/c/g?y/./x"),
    ("g?y/../x", "http://a/b/c/g?y/../x"),
    ("g#s/./x", "http://a/b/c/g#s/./x"),
    ("g#s/../x", "http://a/b/c/g#s/../x"),
  ]
  for item in cases {
    let (reference, expected) = item
    inspect(resolve_uri(base, reference), content=expected)
  }
}

///|
test "resolution requires an absolute base" {
  let base = UriReference::parse("a/b")
  let reference = UriReference::parse("c")
  try reference.resolve(base) catch {
    RelativeBase("a/b") => ()
    _ => fail("expected RelativeBase")
  } noraise {
    _ => fail("expected resolution to fail")
  }
}

///|
test "build absolute URI from encoded components" {
  let uri = UriBuilder::new("https", "api.example.com")
    .push_path("users")
    .push_path("刘明杰")
    .add_query("view", "full details")
    .fragment("profile top")
  inspect(
    uri.to_string(),
    content=(
      #|https://api.example.com/users/%E5%88%98%E6%98%8E%E6%9D%B0?view=full%20details#profile%20top
    ),
  )
}

///|
test "builder encodes structural delimiters in path segments" {
  let uri = UriBuilder::new("https", "example.com")
    .push_path("files")
    .push_path("a/b?c#d")
  inspect(uri.to_string(), content="https://example.com/files/a%2Fb%3Fc%23d")
}

///|
test "builder supports userinfo port and trailing slash" {
  let uri = UriBuilder::new("https", "example.com")
    .userinfo("user name")
    .port(8443)
    .push_paths(["api", "v1"])
    .trailing_slash(true)
  inspect(
    uri.to_string(),
    content="https://user%20name@example.com:8443/api/v1/",
  )
  uri.clear_userinfo().clear_port() |> ignore
  inspect(uri.to_string(), content="https://example.com/api/v1/")
}

///|
test "builder query mutation" {
  let uri = UriBuilder::new("https", "example.com")
    .add_query("tag", "one")
    .add_query("tag", "two")
    .add_query("page", "1")
  inspect(uri.to_string(), content="https://example.com?tag=one&tag=two&page=1")
  uri.set_query("tag", "final").remove_query("page") |> ignore
  inspect(uri.to_string(), content="https://example.com?tag=final")
}

///|
test "builder path stack" {
  let uri = UriBuilder::new("https", "example.com").push_paths(["a", "b", "c"])
  assert_eq(uri.pop_path(), Some("c"))
  inspect(uri.to_string(), content="https://example.com/a/b")
  uri.clear_path().trailing_slash(true) |> ignore
  inspect(uri.to_string(), content="https://example.com/")
}

///|
test "builder fragment can be cleared" {
  let uri = UriBuilder::new("https", "example.com").fragment("one/two")
  inspect(uri.to_string(), content="https://example.com#one/two")
  uri.clear_fragment() |> ignore
  inspect(uri.to_string(), content="https://example.com")
}

///|
test "builder creates parsed URI" {
  let built = UriBuilder::new("https", "example.com")
    .push_path("api")
    .port(443)
    .build()
  assert_eq(built.scheme(), Some("https"))
  inspect(built.path(), content="/api")
  match built.authority() {
    Some(authority) => assert_eq(authority.port(), Some(443))
    None => fail("expected authority")
  }
}

///|
test "builder rejects invalid starting components" {
  try UriBuilder::new("", "example.com") catch {
    EmptyScheme => ()
    _ => fail("expected EmptyScheme")
  } noraise {
    _ => fail("expected failure")
  }
  try UriBuilder::new("1http", "example.com") catch {
    InvalidBuilderScheme("1http") => ()
    _ => fail("expected InvalidBuilderScheme")
  } noraise {
    _ => fail("expected failure")
  }
  try UriBuilder::new("https", "") catch {
    EmptyHost => ()
    _ => fail("expected EmptyHost")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "builder validates port range" {
  let uri = UriBuilder::new("https", "example.com")
  try uri.port(-1) catch {
    InvalidBuilderPort(-1) => ()
    _ => fail("expected InvalidBuilderPort")
  } noraise {
    _ => fail("expected failure")
  }
  try uri.port(65536) catch {
    InvalidBuilderPort(65536) => ()
    _ => fail("expected InvalidBuilderPort")
  } noraise {
    _ => fail("expected failure")
  }
}

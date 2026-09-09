///|
test "match static and parameter route" {
  let route = RoutePattern::parse("/users/{id}/posts/{post}")
  match route.match_path("/users/42/posts/hello") {
    Some(found) => {
      assert_eq(found.get("id"), Some("42"))
      assert_eq(found.get("post"), Some("hello"))
      inspect(found.length(), content="2")
    }
    None => fail("expected match")
  }
}

///|
test "route matching percent-decodes captures" {
  let route = RoutePattern::parse("/users/{name}")
  match route.match_path("/users/%E5%88%98%E6%98%8E%E6%9D%B0") {
    Some(found) => assert_eq(found.get("name"), Some("刘明杰"))
    None => fail("expected match")
  }
}

///|
test "catch-all route captures remaining path" {
  let route = RoutePattern::parse("/files/{*path}")
  match route.match_path("/files/docs/api/index.html") {
    Some(found) => assert_eq(found.get("path"), Some("docs/api/index.html"))
    None => fail("expected match")
  }
}

///|
test "route mismatch returns none" {
  let route = RoutePattern::parse("/users/{id}")
  inspect(route.match_path("/projects/42") is None, content="true")
  inspect(route.match_path("/users") is None, content="true")
  inspect(route.match_path("/users/42/more") is None, content="true")
}

///|
test "match parsed URI path" {
  let route = RoutePattern::parse("/search/{category}")
  let uri = UriReference::parse(
    "https://example.com/search/books?page=2#results",
  )
  match route.match_uri(uri) {
    Some(found) => assert_eq(found.get("category"), Some("books"))
    None => fail("expected match")
  }
}

///|
test "inspect route metadata" {
  let route = RoutePattern::parse("/users/{id}/files/{*path}")
  inspect(route.source(), content="/users/{id}/files/{*path}")
  assert_eq(route.parameter_names(), ["id", "path"])
}

///|
test "render route with encoded values" {
  let route = RoutePattern::parse("/users/{name}/files/{*path}")
  let values : Map[String, String] = Map([])
  values.set("name", "刘明杰")
  values.set("path", "项目/API 文档.md")
  inspect(
    route.render(values),
    content=(
      #|/users/%E5%88%98%E6%98%8E%E6%9D%B0/files/%E9%A1%B9%E7%9B%AE/API%20%E6%96%87%E6%A1%A3.md
    ),
  )
}

///|
test "render reports missing values" {
  let route = RoutePattern::parse("/users/{id}")
  let values : Map[String, String] = Map([])
  try route.render(values) catch {
    MissingRouteValue("id") => ()
    _ => fail("expected MissingRouteValue")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "reject malformed route patterns" {
  try RoutePattern::parse("users/{id}") catch {
    RouteMustStartWithSlash("users/{id}") => ()
    _ => fail("expected RouteMustStartWithSlash")
  } noraise {
    _ => fail("expected failure")
  }
  try RoutePattern::parse("/users/{}") catch {
    EmptyRouteParameter(1) => ()
    _ => fail("expected EmptyRouteParameter")
  } noraise {
    _ => fail("expected failure")
  }
  try RoutePattern::parse("/users/{bad-name}") catch {
    InvalidRouteParameter("bad-name") => ()
    _ => fail("expected InvalidRouteParameter")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "reject duplicate and misplaced catch-all parameters" {
  try RoutePattern::parse("/{id}/posts/{id}") catch {
    DuplicateRouteParameter("id") => ()
    _ => fail("expected DuplicateRouteParameter")
  } noraise {
    _ => fail("expected failure")
  }
  try RoutePattern::parse("/files/{*path}/edit") catch {
    CatchAllMustBeLast("path") => ()
    _ => fail("expected CatchAllMustBeLast")
  } noraise {
    _ => fail("expected failure")
  }
}

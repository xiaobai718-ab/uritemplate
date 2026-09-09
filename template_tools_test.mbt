///|
test "inspect template variable metadata" {
  let template = Template::parse("{/owner,repo}{?labels*,page:3}{#anchor}")
  let variables = template.variables()
  inspect(variables.length(), content="5")
  inspect(variables[0].name(), content="owner")
  inspect(variables[0].operator(), content="/")
  inspect(variables[0].explode(), content="false")
  assert_eq(variables[0].prefix(), None)
  inspect(variables[2].name(), content="labels")
  inspect(variables[2].operator(), content="?")
  inspect(variables[2].explode(), content="true")
  inspect(variables[3].name(), content="page")
  assert_eq(variables[3].prefix(), Some(3))
  inspect(variables[4].operator(), content="#")
}

///|
test "report unique variable names in first-use order" {
  let template = Template::parse("{/owner,repo}{?repo,page}{#owner}")
  assert_eq(template.variable_names(), ["owner", "repo", "page"])
}

///|
test "all template operators expose metadata" {
  let template = Template::parse(
    "{plain}{+reserved}{#fragment}{.label}{/path}{;matrix}{?query}{&more}",
  )
  let operators = template.variables().map(fn(variable) { variable.operator() })
  assert_eq(operators, ["", "+", "#", ".", "/", ";", "?", "&"])
}

///|
test "bindings collection helpers" {
  let bindings = Bindings::new()
    .set_string("name", "MoonBit")
    .set_list("tags", ["uri", "template"])
  inspect(bindings.length(), content="2")
  inspect(bindings.contains("name"), content="true")
  inspect(bindings.contains("missing"), content="false")
  bindings.remove("name") |> ignore
  inspect(bindings.length(), content="1")
  inspect(bindings.contains("name"), content="false")
}

///|
test "find all missing template variables" {
  let template = Template::parse("{/owner,repo}{?page,repo}")
  let bindings = Bindings::new().set_string("owner", "moonbitlang")
  assert_eq(template.missing_variables(bindings), ["repo", "page"])
}

///|
test "checked expansion succeeds with complete bindings" {
  let template = Template::parse("{/owner,repo}{?page}")
  let bindings = Bindings::new()
    .set_string("owner", "moonbitlang")
    .set_string("repo", "core")
    .set_string("page", "2")
  inspect(template.expand_checked(bindings), content="/moonbitlang/core?page=2")
}

///|
test "checked expansion reports every missing binding" {
  let template = Template::parse("{/owner,repo}{?page}")
  let bindings = Bindings::new().set_string("owner", "moonbitlang")
  try template.expand_checked(bindings) catch {
    MissingBindings(names) => assert_eq(names, ["repo", "page"])
  } noraise {
    _ => fail("expected MissingBindings")
  }
}

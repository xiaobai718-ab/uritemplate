///|
test "build template programmatically" {
  let builder = TemplateBuilder::new()
    .literal("https://api.example.com/users")
    .path(["owner", "repo"])
    .query(["page", "language"])
  inspect(
    builder.source(),
    content="https://api.example.com/users{/owner,repo}{?page,language}",
  )
  let template = builder.build()
  let bindings = Bindings::new()
    .set_string("owner", "moonbitlang")
    .set_string("repo", "core")
    .set_string("page", "2")
    .set_string("language", "zh-CN")
  inspect(
    template.expand(bindings),
    content="https://api.example.com/users/moonbitlang/core?page=2&language=zh-CN",
  )
}

///|
test "build every operator programmatically" {
  let variable = VariableRef::new("value")
  let builder = TemplateBuilder::new()
    .expression(Simple, [variable])
    .expression(Reserved, [variable])
    .expression(Fragment, [variable])
    .expression(Label, [variable])
    .expression(Path, [variable])
    .expression(Matrix, [variable])
    .expression(Query, [variable])
    .expression(Continuation, [variable])
  inspect(
    builder.source(),
    content="{value}{+value}{#value}{.value}{/value}{;value}{?value}{&value}",
  )
}

///|
test "variable reference modifiers" {
  let exploded = VariableRef::new("tags").explode()
  inspect(exploded.name(), content="tags")
  inspect(exploded.is_exploded(), content="true")
  assert_eq(exploded.prefix_length(), None)
  let prefixed = VariableRef::new("name").prefix(8)
  inspect(prefixed.is_exploded(), content="false")
  assert_eq(prefixed.prefix_length(), Some(8))
  let builder = TemplateBuilder::new().expression(Query, [exploded, prefixed])
  inspect(builder.source(), content="{?tags*,name:8}")
}

///|
test "builder rejects invalid variable names" {
  try VariableRef::new("") catch {
    EmptyVariableName => ()
    _ => fail("expected EmptyVariableName")
  } noraise {
    _ => fail("expected failure")
  }
  try VariableRef::new("bad name") catch {
    InvalidBuilderVariable("bad name") => ()
    _ => fail("expected InvalidBuilderVariable")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "builder rejects invalid modifiers" {
  try VariableRef::new("name").prefix(0) catch {
    InvalidPrefixLength(0) => ()
    _ => fail("expected InvalidPrefixLength")
  } noraise {
    _ => fail("expected failure")
  }
  let prefixed = VariableRef::new("name").prefix(3)
  try prefixed.explode() catch {
    ConflictingModifiers("name") => ()
    _ => fail("expected ConflictingModifiers")
  } noraise {
    _ => fail("expected failure")
  }
  let exploded = VariableRef::new("name").explode()
  try exploded.prefix(3) catch {
    ConflictingModifiers("name") => ()
    _ => fail("expected ConflictingModifiers")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "builder rejects ambiguous literals" {
  try TemplateBuilder::new().literal("/users/{id}") catch {
    BraceInLiteral("/users/{id}") => ()
    _ => fail("expected BraceInLiteral")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "builder requires variables in expression" {
  try TemplateBuilder::new().expression(Query, []) catch {
    EmptyVariableList => ()
    _ => fail("expected EmptyVariableList")
  } noraise {
    _ => fail("expected failure")
  }
  try TemplateBuilder::new().path([]) catch {
    EmptyVariableList => ()
    _ => fail("expected EmptyVariableList")
  } noraise {
    _ => fail("expected failure")
  }
}

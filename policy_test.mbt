///|
fn policy_uri(text : String) -> UriReference {
  UriReference::parse(text) catch {
    _ => abort("invalid policy test URI")
  }
}

///|
test "web policy accepts ordinary HTTP URIs" {
  let policy = UriPolicy::web()
  policy.validate(policy_uri("https://example.com/a?q=1#top"))
  policy.validate(policy_uri("http://example.com:8080/a"))
}

///|
test "web policy rejects other schemes" {
  try
    UriPolicy::web().validate(policy_uri("file://localhost/etc/passwd"))
  catch {
    SchemeForbidden("file") => ()
    _ => fail("expected SchemeForbidden")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "web policy rejects relative references" {
  try UriPolicy::web().validate(policy_uri("../a")) catch {
    RelativeReferenceForbidden => ()
    _ => fail("expected RelativeReferenceForbidden")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "web policy requires authority" {
  try UriPolicy::web().validate(policy_uri("https:path")) catch {
    AuthorityRequired => ()
    _ => fail("expected AuthorityRequired")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "web policy rejects userinfo by default" {
  try UriPolicy::web().validate(policy_uri("https://user@example.com/")) catch {
    UserinfoForbidden => ()
    _ => fail("expected UserinfoForbidden")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "policy can restrict ports" {
  let policy = UriPolicy::web().ports([443, 8443])
  policy.validate(policy_uri("https://example.com:8443/"))
  try policy.validate(policy_uri("https://example.com:8080/")) catch {
    PortForbidden(8080) => ()
    _ => fail("expected PortForbidden")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "policy can forbid fragments" {
  let policy = UriPolicy::web().fragment(false)
  try policy.validate(policy_uri("https://example.com/#top")) catch {
    FragmentForbidden => ()
    _ => fail("expected FragmentForbidden")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "policy enforces input length" {
  let policy = UriPolicy::permissive().max_length(5)
  try policy.validate(policy_uri("abcdef")) catch {
    InputTooLong(6, 5) => ()
    _ => fail("expected InputTooLong")
  } noraise {
    _ => fail("expected failure")
  }
}

///|
test "permissive policy accepts relative and userinfo" {
  let policy = UriPolicy::permissive()
  policy.validate(policy_uri("../a"))
  policy.validate(policy_uri("custom://user@example.com/a"))
}

///|
test "policy settings can be changed" {
  let policy = UriPolicy::web()
    .schemes(["git"])
    .relative(true)
    .authority(false)
    .userinfo(true)
  policy.validate(policy_uri("git:path"))
  policy.validate(policy_uri("relative/path"))
  policy.validate(policy_uri("git://user@example.com/repo"))
}

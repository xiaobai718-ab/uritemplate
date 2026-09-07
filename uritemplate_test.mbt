///|
fn standard_bindings() -> Bindings {
  Bindings::new()
  .set_string("count", "one, two, three")
  .set_string("dom", "example.com")
  .set_string("dub", "me/too")
  .set_string("hello", "Hello World!")
  .set_string("half", "50%")
  .set_string("var", "value")
  .set_string("who", "fred")
  .set_string("base", "http://example.com/home/")
  .set_string("path", "/foo/bar")
  .set_string("x", "1024")
  .set_string("y", "768")
  .set_string("empty", "")
  .set_list("list", ["red", "green", "blue"])
  .set_list("empty_list", [])
  .set_assoc("keys", [("semi", ";"), ("dot", "."), ("comma", ",")])
}

///|
fn check(template : String, expected : String) -> Unit raise {
  let actual = expand(template, standard_bindings()) catch {
    _ => "<unexpected expansion error>"
  }
  assert_eq(actual, expected)
}

///|
test "RFC 6570 level 1 simple expansion" {
  check("{var}", "value")
  check("{hello}", "Hello%20World%21")
  check("{var,hello}", "value,Hello%20World%21")
  check("X{empty}", "X")
  check("X{undef}Y", "XY")
}

///|
test "RFC 6570 level 2 reserved expansion" {
  check("{+var}", "value")
  check("{+hello}", "Hello%20World!")
  check("{+path}/here", "/foo/bar/here")
  check("here?ref={+path}", "here?ref=/foo/bar")
}

///|
test "RFC 6570 level 2 fragment expansion" {
  check("X{#var}", "X#value")
  check("X{#hello}", "X#Hello%20World!")
  check("{#path,x}", "#/foo/bar,1024")
  check("X{#undef}Y", "XY")
}

///|
test "RFC 6570 level 3 label and path expansion" {
  check("map?{x,y}", "map?1024,768")
  check("{x,hello,y}", "1024,Hello%20World%21,768")
  check("{.who}", ".fred")
  check("{.who,who}", ".fred.fred")
  check("{/who}", "/fred")
  check("{/who,who}", "/fred/fred")
  check("{/undef}", "")
}

///|
test "RFC 6570 level 3 matrix and query expansion" {
  check("{;x,y}", ";x=1024;y=768")
  check("{;x,y,empty}", ";x=1024;y=768;empty")
  check("{?x,y}", "?x=1024&y=768")
  check("{?x,y,empty}", "?x=1024&y=768&empty=")
  check("?fixed=yes{&x}", "?fixed=yes&x=1024")
  check("{&x,y,empty}", "&x=1024&y=768&empty=")
}

///|
test "RFC 6570 level 4 prefix modifier" {
  check("{var:3}", "val")
  check("{var:30}", "value")
  check("{hello:5}", "Hello")
  check("{+path:6}/here", "/foo/b/here")
}

///|
test "RFC 6570 list expansion" {
  check("{list}", "red,green,blue")
  check("{list*}", "red,green,blue")
  check("{/list}", "/red,green,blue")
  check("{/list*}", "/red/green/blue")
  check("{;list}", ";list=red,green,blue")
  check("{;list*}", ";list=red;list=green;list=blue")
  check("{?list}", "?list=red,green,blue")
  check("{?list*}", "?list=red&list=green&list=blue")
  check("{?empty_list}", "")
}

///|
test "RFC 6570 associative expansion" {
  check("{keys}", "semi,%3B,dot,.,comma,%2C")
  check("{keys*}", "semi=%3B,dot=.,comma=%2C")
  check("{/keys*}", "/semi=%3B/dot=./comma=%2C")
  check("{;keys}", ";keys=semi,%3B,dot,.,comma,%2C")
  check("{;keys*}", ";semi=%3B;dot=.;comma=%2C")
  check("{?keys}", "?keys=semi,%3B,dot,.,comma,%2C")
  check("{?keys*}", "?semi=%3B&dot=.&comma=%2C")
}

///|
test "UTF-8 percent encoding" {
  assert_eq(encode("你好 MoonBit"), "%E4%BD%A0%E5%A5%BD%20MoonBit")
  assert_eq(encode("/a?b=c", allow_reserved=true), "/a?b=c")
  assert_eq(encode("/a?b=c"), "%2Fa%3Fb%3Dc")
}

///|
test "syntax errors are structured" {
  try expand("before{var", standard_bindings()) catch {
    UnclosedExpression(6) => ()
    _ => fail("expected UnclosedExpression")
  } noraise {
    _ => fail("expected expansion to fail")
  }
  try expand("{}", standard_bindings()) catch {
    EmptyExpression(_) => ()
    _ => fail("expected EmptyExpression")
  } noraise {
    _ => fail("expected expansion to fail")
  }
  try expand("{var:0}", standard_bindings()) catch {
    InvalidModifier("var:0") => ()
    _ => fail("expected InvalidModifier")
  } noraise {
    _ => fail("expected expansion to fail")
  }
}

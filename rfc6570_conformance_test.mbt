///|
// These deterministic vectors mirror the official uri-templates test suite.
// Keeping them in MoonBit makes conformance checks available without network
// access, JSON parsing, or an external test runner.
fn official_bindings() -> Bindings {
  Bindings::new()
  .set_list("count", ["one", "two", "three"])
  .set_list("dom", ["example", "com"])
  .set_string("dub", "me/too")
  .set_string("hello", "Hello World!")
  .set_string("half", "50%")
  .set_string("var", "value")
  .set_string("who", "fred")
  .set_string("base", "http://example.com/home/")
  .set_string("path", "/foo/bar")
  .set_list("list", ["red", "green", "blue"])
  .set_assoc("keys", [("semi", ";"), ("dot", "."), ("comma", ",")])
  .set_string("v", "6")
  .set_string("x", "1024")
  .set_string("y", "768")
  .set_string("empty", "")
  .set_assoc("empty_keys", [])
}

///|
fn check_official(cases : Array[(String, String)]) -> Unit raise {
  let bindings = official_bindings()
  for item in cases {
    let (template, expected) = item
    inspect(expand(template, bindings), content=expected)
  }
}

///|
test "official simple string expansion vectors" {
  check_official([
    ("{var}", "value"),
    ("{hello}", "Hello%20World%21"),
    ("{half}", "50%25"),
    ("O{empty}X", "OX"),
    ("O{undef}X", "OX"),
    ("{x,y}", "1024,768"),
    ("?{x,empty}", "?1024,"),
    ("?{x,undef}", "?1024"),
    ("{var:3}", "val"),
    ("{list*}", "red,green,blue"),
    ("{empty_keys}", ""),
  ])
}

///|
test "official reserved expansion vectors" {
  check_official([
    ("{+var}", "value"),
    ("{/var,empty}", "/value/"),
    ("{/var,undef}", "/value"),
    ("{+hello}", "Hello%20World!"),
    ("{+half}", "50%25"),
    ("{base}index", "http%3A%2F%2Fexample.com%2Fhome%2Findex"),
    ("{+base}index", "http://example.com/home/index"),
    ("O{+empty}X", "OX"),
    ("{+path:6}/here", "/foo/b/here"),
    ("up{+path}{var}/here", "up/foo/barvalue/here"),
    ("{+x,hello,y}", "1024,Hello%20World!,768"),
    ("{+list}", "red,green,blue"),
    ("{+keys}", "semi,;,dot,.,comma,,"),
    ("{+keys*}", "semi=;,dot=.,comma=,"),
  ])
}

///|
test "official fragment expansion vectors" {
  check_official([
    ("{#var}", "#value"),
    ("{#hello}", "#Hello%20World!"),
    ("{#half}", "#50%25"),
    ("foo{#empty}", "foo#"),
    ("foo{#undef}", "foo"),
    ("{#path,x}/here", "#/foo/bar,1024/here"),
    ("{#list*}", "#red,green,blue"),
    ("{#keys}", "#semi,;,dot,.,comma,,"),
    ("{#keys*}", "#semi=;,dot=.,comma=,"),
  ])
}

///|
test "official label expansion vectors" {
  check_official([
    ("{.who}", ".fred"),
    ("{.who,who}", ".fred.fred"),
    ("{.half,who}", ".50%25.fred"),
    ("www{.dom*}", "www.example.com"),
    ("X{.var:3}", "X.val"),
    ("X{.empty}", "X."),
    ("X{.undef}", "X"),
    ("X{.list}", "X.red,green,blue"),
    ("X{.list*}", "X.red.green.blue"),
    ("X{.empty_keys*}", "X"),
  ])
}

///|
test "official path segment expansion vectors" {
  check_official([
    ("{/who}", "/fred"),
    ("{/who,who}", "/fred/fred"),
    ("{/half,who}", "/50%25/fred"),
    ("{/who,dub}", "/fred/me%2Ftoo"),
    ("{/var,x}/here", "/value/1024/here"),
    ("{/var:1,var}", "/v/value"),
    ("{/list}", "/red,green,blue"),
    ("{/list*}", "/red/green/blue"),
    ("{/list*,path:4}", "/red/green/blue/%2Ffoo"),
    ("{/keys}", "/semi,%3B,dot,.,comma,%2C"),
    ("{/keys*}", "/semi=%3B/dot=./comma=%2C"),
  ])
}

///|
test "official matrix expansion vectors" {
  check_official([
    ("{;who}", ";who=fred"),
    ("{;half}", ";half=50%25"),
    ("{;empty}", ";empty"),
    ("{;hello:5}", ";hello=Hello"),
    ("{;v,empty,who}", ";v=6;empty;who=fred"),
    ("{;v,bar,who}", ";v=6;who=fred"),
    ("{;list}", ";list=red,green,blue"),
    ("{;list*}", ";list=red;list=green;list=blue"),
    ("{;keys}", ";keys=semi,%3B,dot,.,comma,%2C"),
    ("{;keys*}", ";semi=%3B;dot=.;comma=%2C"),
  ])
}

///|
test "official query expansion vectors" {
  check_official([
    ("{?who}", "?who=fred"),
    ("{?half}", "?half=50%25"),
    ("{?x,y}", "?x=1024&y=768"),
    ("{?x,y,empty}", "?x=1024&y=768&empty="),
    ("{?x,y,undef}", "?x=1024&y=768"),
    ("{?var:3}", "?var=val"),
    ("{?list}", "?list=red,green,blue"),
    ("{?list*}", "?list=red&list=green&list=blue"),
    ("{?keys}", "?keys=semi,%3B,dot,.,comma,%2C"),
    ("{?keys*}", "?semi=%3B&dot=.&comma=%2C"),
  ])
}

///|
test "official query continuation vectors" {
  check_official([
    ("{&who}", "&who=fred"),
    ("{&half}", "&half=50%25"),
    ("?fixed=yes{&x}", "?fixed=yes&x=1024"),
    ("{&x,y,empty}", "&x=1024&y=768&empty="),
    ("{&var:3}", "&var=val"),
    ("{&list}", "&list=red,green,blue"),
    ("{&list*}", "&list=red&list=green&list=blue"),
    ("{&keys}", "&keys=semi,%3B,dot,.,comma,%2C"),
    ("{&keys*}", "&semi=%3B&dot=.&comma=%2C"),
  ])
}

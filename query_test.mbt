///|
test "parse ordinary query parameters" {
  let params = QueryParams::parse("name=MoonBit&page=2")
  inspect(params.length(), content="2")
  assert_eq(params.get("name"), Some("MoonBit"))
  assert_eq(params.get("page"), Some("2"))
  assert_eq(params.get("missing"), None)
  inspect(params.contains("name"), content="true")
  inspect(params.contains("other"), content="false")
}

///|
test "parse leading question mark and empty values" {
  let params = QueryParams::parse("?enabled=&flag")
  assert_eq(params.get("enabled"), Some(""))
  assert_eq(params.get("flag"), Some(""))
  inspect(params.to_string(), content="enabled=&flag=")
}

///|
test "parse duplicate keys in insertion order" {
  let params = QueryParams::parse("tag=moonbit&tag=web&tag=api")
  assert_eq(params.get_all("tag"), ["moonbit", "web", "api"])
  inspect(params.to_string(), content="tag=moonbit&tag=web&tag=api")
}

///|
test "query parsing decodes form syntax" {
  let params = QueryParams::parse(
    "keyword=MoonBit+%E6%95%99%E7%A8%8B&language=zh-CN",
  )
  assert_eq(params.get("keyword"), Some("MoonBit 教程"))
  assert_eq(params.get("language"), Some("zh-CN"))
}

///|
test "query plus handling is configurable" {
  let form = QueryParams::parse("value=a+b")
  assert_eq(form.get("value"), Some("a b"))
  let strict = QueryParams::parse("value=a+b", plus_as_space=false)
  assert_eq(strict.get("value"), Some("a+b"))
}

///|
test "semicolon separator is configurable" {
  let normal = QueryParams::parse("a=1;b=2")
  assert_eq(normal.get("a"), Some("1;b=2"))
  let compatible = QueryParams::parse("a=1;b=2", semicolon_separator=true)
  assert_eq(compatible.get("a"), Some("1"))
  assert_eq(compatible.get("b"), Some("2"))
}

///|
test "construct and render query parameters" {
  let params = QueryParams::new()
    .add("keyword", "MoonBit 教程")
    .add("tag", "network")
    .add("tag", "基础库")
  inspect(
    params.to_string(),
    content="keyword=MoonBit+%E6%95%99%E7%A8%8B&tag=network&tag=%E5%9F%BA%E7%A1%80%E5%BA%93",
  )
  inspect(
    params.to_rfc3986(),
    content="keyword=MoonBit%20%E6%95%99%E7%A8%8B&tag=network&tag=%E5%9F%BA%E7%A1%80%E5%BA%93",
  )
}

///|
test "set replaces all values and preserves other entries" {
  let params = QueryParams::parse("a=1&b=2&a=3").set("a", "4")
  inspect(params.to_string(), content="b=2&a=4")
  assert_eq(params.get_all("a"), ["4"])
}

///|
test "remove deletes every matching value" {
  let params = QueryParams::parse("a=1&b=2&a=3").remove("a")
  inspect(params.to_string(), content="b=2")
  inspect(params.contains("a"), content="false")
}

///|
test "from array copies its input" {
  let source = [("a", "1")]
  let params = QueryParams::from_array(source)
  source.push(("b", "2"))
  inspect(params.length(), content="1")
  assert_eq(params.to_array(), [("a", "1")])
}

///|
test "append parameters to URL" {
  let params = QueryParams::new().add("page", "2").add("q", "Moon Bit")
  inspect(
    params.append_to("https://example.com/search"),
    content="https://example.com/search?page=2&q=Moon+Bit",
  )
  inspect(
    params.append_to("https://example.com/search?lang=zh"),
    content="https://example.com/search?lang=zh&page=2&q=Moon+Bit",
  )
  inspect(
    params.append_to("https://example.com/search#results"),
    content="https://example.com/search?page=2&q=Moon+Bit#results",
  )
}

///|
test "empty parameters do not change URL" {
  let params = QueryParams::new()
  inspect(params.is_empty(), content="true")
  inspect(
    params.append_to("https://example.com/#top"),
    content="https://example.com/#top",
  )
}

///|
test "query errors identify field and side" {
  try QueryParams::parse("ok=1&bad%GG=2") catch {
    InvalidKey(1, InvalidEscape(3, "%GG")) => ()
    _ => fail("expected InvalidKey")
  } noraise {
    _ => fail("expected parsing to fail")
  }
  try QueryParams::parse("ok=1&bad=%FF") catch {
    InvalidValue(1, InvalidUtf8) => ()
    _ => fail("expected InvalidValue")
  } noraise {
    _ => fail("expected parsing to fail")
  }
}

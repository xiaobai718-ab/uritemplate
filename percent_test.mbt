///|
test "percent decode ASCII escapes" {
  inspect(percent_decode("hello%20world"), content="hello world")
  inspect(percent_decode("%41%42%43"), content="ABC")
  inspect(percent_decode("safe-._~"), content="safe-._~")
  inspect(percent_decode("%2Fapi%3Fpage%3D1"), content="/api?page=1")
}

///|
test "percent decode UTF-8 escapes" {
  inspect(percent_decode("%E4%BD%A0%E5%A5%BD"), content="你好")
  inspect(percent_decode("caf%C3%A9"), content="café")
  inspect(percent_decode("%F0%9F%8C%99"), content="🌙")
  inspect(
    percent_decode("原文%20and%20encoded"),
    content="原文 and encoded",
  )
}

///|
test "plus decoding is configurable" {
  inspect(percent_decode("a+b"), content="a+b")
  inspect(percent_decode("a+b", plus_as_space=true), content="a b")
  inspect(percent_decode("a%2Bb", plus_as_space=true), content="a+b")
}

///|
test "form encoding uses plus for spaces" {
  inspect(form_encode("hello world"), content="hello+world")
  inspect(form_encode("a+b"), content="a%2Bb")
  inspect(form_encode("你好 MoonBit"), content="%E4%BD%A0%E5%A5%BD+MoonBit")
}

///|
test "reject incomplete percent escapes" {
  try percent_decode("abc%") catch {
    IncompleteEscape(3) => ()
    _ => fail("expected IncompleteEscape")
  } noraise {
    _ => fail("expected decoding to fail")
  }
  try percent_decode("abc%A") catch {
    IncompleteEscape(3) => ()
    _ => fail("expected IncompleteEscape")
  } noraise {
    _ => fail("expected decoding to fail")
  }
}

///|
test "reject invalid percent digits" {
  try percent_decode("%GG") catch {
    InvalidEscape(0, "%GG") => ()
    _ => fail("expected InvalidEscape")
  } noraise {
    _ => fail("expected decoding to fail")
  }
}

///|
test "reject invalid encoded UTF-8" {
  try percent_decode("%FF") catch {
    InvalidUtf8 => ()
    _ => fail("expected InvalidUtf8")
  } noraise {
    _ => fail("expected decoding to fail")
  }
}

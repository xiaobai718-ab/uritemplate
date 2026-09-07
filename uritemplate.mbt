///|
/// A value available to a URI Template expression.
pub(all) enum Value {
  Scalar(String)
  List(Array[String])
  Assoc(Array[(String, String)])
} derive(Debug, Eq)

///|
/// A mutable collection of named values used during expansion.
pub(all) struct Bindings {
  values : Map[String, Value]
}

///|
pub fn Bindings::new() -> Bindings {
  { values: Map([]), }
}

///|
pub fn Bindings::set_string(
  self : Bindings,
  name : String,
  value : String,
) -> Bindings {
  self.values.set(name, Scalar(value))
  self
}

///|
pub fn Bindings::set_list(
  self : Bindings,
  name : String,
  value : Array[String],
) -> Bindings {
  self.values.set(name, List(value))
  self
}

///|
pub fn Bindings::set_assoc(
  self : Bindings,
  name : String,
  value : Array[(String, String)],
) -> Bindings {
  self.values.set(name, Assoc(value))
  self
}

///|
pub suberror ExpandError {
  UnclosedExpression(Int)
  EmptyExpression(Int)
  InvalidVariable(String)
  InvalidModifier(String)
} derive(Debug, Eq)

///|
priv struct Operator {
  prefix : String
  separator : String
  named : Bool
  if_empty : String
  allow_reserved : Bool
}

///|
priv struct VarSpec {
  name : String
  explode : Bool
  prefix : Int?
}

///|
fn chars_to_string(chars : Array[Char]) -> String {
  let result : String = [..chars]
  result
}

///|
fn char_slice(chars : Array[Char], start : Int, end : Int) -> String {
  let result : Array[Char] = []
  for i = start; i < end; i = i + 1 {
    result.push(chars[i])
  }
  chars_to_string(result)
}

///|
fn is_alpha_numeric(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')
}

///|
fn is_unreserved(c : Char) -> Bool {
  is_alpha_numeric(c) || c == '-' || c == '.' || c == '_' || c == '~'
}

///|
fn is_reserved(c : Char) -> Bool {
  c == ':' ||
  c == '/' ||
  c == '?' ||
  c == '#' ||
  c == '[' ||
  c == ']' ||
  c == '@' ||
  c == '!' ||
  c == '$' ||
  c == '&' ||
  c == '\'' ||
  c == '(' ||
  c == ')' ||
  c == '*' ||
  c == '+' ||
  c == ',' ||
  c == ';' ||
  c == '='
}

///|
fn is_hex_digit(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
fn hex_digit(value : Int) -> Char {
  match value {
    0 => '0'
    1 => '1'
    2 => '2'
    3 => '3'
    4 => '4'
    5 => '5'
    6 => '6'
    7 => '7'
    8 => '8'
    9 => '9'
    10 => 'A'
    11 => 'B'
    12 => 'C'
    13 => 'D'
    14 => 'E'
    _ => 'F'
  }
}

///|
fn append_encoded_byte(out : Array[Char], value : Int) -> Unit {
  out.push('%')
  out.push(hex_digit((value >> 4) & 15))
  out.push(hex_digit(value & 15))
}

///|
fn append_utf8_encoded(out : Array[Char], c : Char) -> Unit {
  let value = c.to_int()
  if value <= 0x7F {
    append_encoded_byte(out, value)
  } else if value <= 0x7FF {
    append_encoded_byte(out, 0xC0 | (value >> 6))
    append_encoded_byte(out, 0x80 | (value & 0x3F))
  } else if value <= 0xFFFF {
    append_encoded_byte(out, 0xE0 | (value >> 12))
    append_encoded_byte(out, 0x80 | ((value >> 6) & 0x3F))
    append_encoded_byte(out, 0x80 | (value & 0x3F))
  } else {
    append_encoded_byte(out, 0xF0 | (value >> 18))
    append_encoded_byte(out, 0x80 | ((value >> 12) & 0x3F))
    append_encoded_byte(out, 0x80 | ((value >> 6) & 0x3F))
    append_encoded_byte(out, 0x80 | (value & 0x3F))
  }
}

///|
/// Percent-encode a value according to RFC 3986. Reserved characters are
/// retained only for the `+` and `#` URI Template operators.
pub fn encode(value : String, allow_reserved? : Bool = false) -> String {
  let out : Array[Char] = []
  let chars : Array[Char] = value.to_array()
  let mut index = 0
  while index < chars.length() {
    let c = chars[index]
    if is_unreserved(c) || (allow_reserved && is_reserved(c)) {
      out.push(c)
    } else if allow_reserved &&
      c == '%' &&
      index + 2 < chars.length() &&
      is_hex_digit(chars[index + 1]) &&
      is_hex_digit(chars[index + 2]) {
      out.push(c)
      out.push(chars[index + 1])
      out.push(chars[index + 2])
      index = index + 2
    } else {
      append_utf8_encoded(out, c)
    }
    index = index + 1
  }
  chars_to_string(out)
}

///|
fn operator_for(c : Char?) -> Operator {
  match c {
    Some('+') =>
      {
        prefix: "",
        separator: ",",
        named: false,
        if_empty: "",
        allow_reserved: true,
      }
    Some('#') =>
      {
        prefix: "#",
        separator: ",",
        named: false,
        if_empty: "",
        allow_reserved: true,
      }
    Some('.') =>
      {
        prefix: ".",
        separator: ".",
        named: false,
        if_empty: "",
        allow_reserved: false,
      }
    Some('/') =>
      {
        prefix: "/",
        separator: "/",
        named: false,
        if_empty: "",
        allow_reserved: false,
      }
    Some(';') =>
      {
        prefix: ";",
        separator: ";",
        named: true,
        if_empty: "",
        allow_reserved: false,
      }
    Some('?') =>
      {
        prefix: "?",
        separator: "&",
        named: true,
        if_empty: "=",
        allow_reserved: false,
      }
    Some('&') =>
      {
        prefix: "&",
        separator: "&",
        named: true,
        if_empty: "=",
        allow_reserved: false,
      }
    _ =>
      {
        prefix: "",
        separator: ",",
        named: false,
        if_empty: "",
        allow_reserved: false,
      }
  }
}

///|
fn is_operator(c : Char) -> Bool {
  c == '+' ||
  c == '#' ||
  c == '.' ||
  c == '/' ||
  c == ';' ||
  c == '?' ||
  c == '&'
}

///|
fn parse_positive_int(text : String) -> Int? {
  if text.length() == 0 {
    return None
  }
  let mut result = 0
  for c in text {
    if c < '0' || c > '9' {
      return None
    }
    result = result * 10 + (c.to_int() - '0'.to_int())
  }
  if result > 0 {
    Some(result)
  } else {
    None
  }
}

///|
fn valid_var_char(c : Char) -> Bool {
  is_alpha_numeric(c) || c == '_' || c == '.' || c == '%'
}

///|
fn parse_varspec(text : String) -> VarSpec raise ExpandError {
  let chars : Array[Char] = [..text]
  if chars.length() == 0 {
    raise InvalidVariable(text)
  }
  let mut end = chars.length()
  let mut explode = false
  let mut prefix : Int? = None
  if chars[end - 1] == '*' {
    explode = true
    end = end - 1
  }
  let mut colon = -1
  for i = 0; i < end; i = i + 1 {
    if chars[i] == ':' {
      colon = i
    }
  }
  if colon >= 0 {
    if explode {
      raise InvalidModifier(text)
    }
    let digits = char_slice(chars, colon + 1, end)
    prefix = match parse_positive_int(digits) {
      Some(value) => Some(value)
      None => raise InvalidModifier(text)
    }
    end = colon
  }
  if end == 0 {
    raise InvalidVariable(text)
  }
  for i = 0; i < end; i = i + 1 {
    if !valid_var_char(chars[i]) {
      raise InvalidVariable(text)
    }
  }
  { name: char_slice(chars, 0, end), explode, prefix, }
}

///|
fn truncate(value : String, prefix : Int?) -> String {
  match prefix {
    None => value
    Some(limit) => {
      let chars : Array[Char] = [..value]
      char_slice(
        chars,
        0,
        if chars.length() < limit {
          chars.length()
        } else {
          limit
        },
      )
    }
  }
}

///|
fn join(parts : Array[String], separator : String) -> String {
  let out : Array[Char] = []
  for i, part in parts {
    if i > 0 {
      for c in separator {
        out.push(c)
      }
    }
    for c in part {
      out.push(c)
    }
  }
  chars_to_string(out)
}

///|
fn named_value(name : String, value : String, op : Operator) -> String {
  if !op.named {
    value
  } else if value == "" {
    name + op.if_empty
  } else {
    name + "=" + value
  }
}

///|
fn expand_value(spec : VarSpec, value : Value, op : Operator) -> Array[String] {
  match value {
    Scalar(raw) => {
      let encoded = encode(
        truncate(raw, spec.prefix),
        allow_reserved=op.allow_reserved,
      )
      [named_value(spec.name, encoded, op)]
    }
    List(items) =>
      if items.length() == 0 {
        []
      } else {
        let encoded = items.map(fn(item) {
          encode(item, allow_reserved=op.allow_reserved)
        })
        if spec.explode {
          encoded.map(fn(item) { named_value(spec.name, item, op) })
        } else {
          [named_value(spec.name, join(encoded, ","), op)]
        }
      }
    Assoc(entries) =>
      if entries.length() == 0 {
        []
      } else if spec.explode {
        entries.map(fn(entry) {
          let (key, raw) = entry
          let encoded_key = encode(key, allow_reserved=op.allow_reserved)
          let encoded_value = encode(raw, allow_reserved=op.allow_reserved)
          if op.named {
            encoded_key + "=" + encoded_value
          } else {
            encoded_key + "=" + encoded_value
          }
        })
      } else {
        let parts : Array[String] = []
        for entry in entries {
          let (key, raw) = entry
          parts.push(encode(key, allow_reserved=op.allow_reserved))
          parts.push(encode(raw, allow_reserved=op.allow_reserved))
        }
        [named_value(spec.name, join(parts, ","), op)]
      }
  }
}

///|
fn split_varspecs(text : String) -> Array[String] {
  let result : Array[String] = []
  let current : Array[Char] = []
  for c in text {
    if c == ',' {
      result.push(chars_to_string(current))
      current.clear()
    } else {
      current.push(c)
    }
  }
  result.push(chars_to_string(current))
  result
}

///|
fn expand_expression(
  expression : String,
  bindings : Bindings,
) -> String raise ExpandError {
  let chars : Array[Char] = [..expression]
  if chars.length() == 0 {
    raise EmptyExpression(0)
  }
  let op_char = if is_operator(chars[0]) { Some(chars[0]) } else { None }
  let op = operator_for(op_char)
  let body_start = if op_char is Some(_) { 1 } else { 0 }
  let body = char_slice(chars, body_start, chars.length())
  if body == "" {
    raise EmptyExpression(0)
  }
  let expanded : Array[String] = []
  for raw_spec in split_varspecs(body) {
    let spec = parse_varspec(raw_spec)
    match bindings.values.get(spec.name) {
      Some(value) =>
        for part in expand_value(spec, value, op) {
          expanded.push(part)
        }
      None => ()
    }
  }
  if expanded.length() == 0 {
    ""
  } else {
    op.prefix + join(expanded, op.separator)
  }
}

///|
/// Expand an RFC 6570 URI Template using the supplied bindings.
pub fn expand(
  template : String,
  bindings : Bindings,
) -> String raise ExpandError {
  let chars : Array[Char] = [..template]
  let out : Array[Char] = []
  let mut i = 0
  while i < chars.length() {
    if chars[i] != '{' {
      out.push(chars[i])
      i = i + 1
      continue
    }
    let opened_at = i
    let mut close = i + 1
    while close < chars.length() && chars[close] != '}' {
      if chars[close] == '{' {
        raise InvalidVariable(char_slice(chars, opened_at, close + 1))
      }
      close = close + 1
    }
    if close == chars.length() {
      raise UnclosedExpression(opened_at)
    }
    let expression = char_slice(chars, i + 1, close)
    let replacement = expand_expression(expression, bindings)
    for c in replacement {
      out.push(c)
    }
    i = close + 1
  }
  chars_to_string(out)
}

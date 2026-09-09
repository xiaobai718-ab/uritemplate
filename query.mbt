///|
pub suberror QueryError {
  InvalidKey(Int, PercentDecodeError)
  InvalidValue(Int, PercentDecodeError)
} derive(Debug, Eq)

///|
/// An ordered multi-map of query parameters. Duplicate keys are preserved.
pub struct QueryParams {
  priv entries : Array[(String, String)]
}

///|
pub fn QueryParams::new() -> QueryParams {
  { entries: [], }
}

///|
pub fn QueryParams::from_array(
  entries : Array[(String, String)],
) -> QueryParams {
  { entries: entries.copy(), }
}

///|
/// Parse a query string, optionally accepting semicolons as separators.
pub fn QueryParams::parse(
  input : String,
  semicolon_separator? : Bool = false,
  plus_as_space? : Bool = true,
) -> QueryParams raise QueryError {
  let chars : Array[Char] = [..input]
  let start = if chars.length() > 0 && chars[0] == '?' { 1 } else { 0 }
  let entries : Array[(String, String)] = []
  let field : Array[Char] = []
  let mut field_index = 0
  fn flush(
    field : Array[Char],
    field_index : Int,
    entries : Array[(String, String)],
    plus_as_space : Bool,
  ) -> Unit raise QueryError {
    if field.length() == 0 {
      return
    }
    let equals = uri_index_of(field, '=', 0)
    let key_encoded = if equals >= 0 {
      char_slice(field, 0, equals)
    } else {
      chars_to_string(field)
    }
    let value_encoded = if equals >= 0 {
      char_slice(field, equals + 1, field.length())
    } else {
      ""
    }
    let key = percent_decode(key_encoded, plus_as_space~) catch {
      error => raise InvalidKey(field_index, error)
    }
    let value = percent_decode(value_encoded, plus_as_space~) catch {
      error => raise InvalidValue(field_index, error)
    }
    entries.push((key, value))
  }
  for index = start; index < chars.length(); index = index + 1 {
    let separator = chars[index] == '&' ||
      (semicolon_separator && chars[index] == ';')
    if separator {
      flush(field, field_index, entries, plus_as_space)
      field.clear()
      field_index = field_index + 1
    } else {
      field.push(chars[index])
    }
  }
  flush(field, field_index, entries, plus_as_space)
  { entries, }
}

///|
pub fn QueryParams::add(
  self : QueryParams,
  key : String,
  value : String,
) -> QueryParams {
  self.entries.push((key, value))
  self
}

///|
pub fn QueryParams::set(
  self : QueryParams,
  key : String,
  value : String,
) -> QueryParams {
  let retained : Array[(String, String)] = []
  for entry in self.entries {
    if entry.0 != key {
      retained.push(entry)
    }
  }
  self.entries.clear()
  for entry in retained {
    self.entries.push(entry)
  }
  self.entries.push((key, value))
  self
}

///|
pub fn QueryParams::remove(self : QueryParams, key : String) -> QueryParams {
  let retained : Array[(String, String)] = []
  for entry in self.entries {
    if entry.0 != key {
      retained.push(entry)
    }
  }
  self.entries.clear()
  for entry in retained {
    self.entries.push(entry)
  }
  self
}

///|
pub fn QueryParams::get(self : QueryParams, key : String) -> String? {
  for entry in self.entries {
    if entry.0 == key {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn QueryParams::get_all(self : QueryParams, key : String) -> Array[String] {
  let values : Array[String] = []
  for entry in self.entries {
    if entry.0 == key {
      values.push(entry.1)
    }
  }
  values
}

///|
pub fn QueryParams::contains(self : QueryParams, key : String) -> Bool {
  self.get(key) is Some(_)
}

///|
pub fn QueryParams::length(self : QueryParams) -> Int {
  self.entries.length()
}

///|
pub fn QueryParams::is_empty(self : QueryParams) -> Bool {
  self.entries.length() == 0
}

///|
pub fn QueryParams::to_array(self : QueryParams) -> Array[(String, String)] {
  self.entries.copy()
}

///|
pub fn QueryParams::to_string(self : QueryParams) -> String {
  let fields : Array[String] = []
  for entry in self.entries {
    fields.push(form_encode(entry.0) + "=" + form_encode(entry.1))
  }
  join(fields, "&")
}

///|
pub fn QueryParams::to_rfc3986(self : QueryParams) -> String {
  let fields : Array[String] = []
  for entry in self.entries {
    fields.push(encode(entry.0) + "=" + encode(entry.1))
  }
  join(fields, "&")
}

///|
pub fn QueryParams::append_to(self : QueryParams, url : String) -> String {
  if self.is_empty() {
    return url
  }
  let chars : Array[Char] = [..url]
  let hash = uri_index_of(chars, '#', 0)
  let base_end = if hash >= 0 { hash } else { chars.length() }
  let base = char_slice(chars, 0, base_end)
  let fragment = if hash >= 0 {
    char_slice(chars, hash, chars.length())
  } else {
    ""
  }
  let separator = if uri_index_of([..base], '?', 0) >= 0 {
    if uri_ends_with(base, "?") || uri_ends_with(base, "&") {
      ""
    } else {
      "&"
    }
  } else {
    "?"
  }
  base + separator + self.to_string() + fragment
}

///|
fn ascii_lower(text : String) -> String {
  let output : Array[Char] = []
  for c in text {
    if c >= 'A' && c <= 'Z' {
      output.push((c.to_int() + ('a'.to_int() - 'A'.to_int())).unsafe_to_char())
    } else {
      output.push(c)
    }
  }
  chars_to_string(output)
}

///|
fn upper_hex_char(c : Char) -> Char {
  if c >= 'a' && c <= 'f' {
    (c.to_int() - 'a'.to_int() + 'A'.to_int()).unsafe_to_char()
  } else {
    c
  }
}

///|
fn normalize_percent_component(text : String) -> String {
  let chars : Array[Char] = [..text]
  let output : Array[Char] = []
  let mut index = 0
  while index < chars.length() {
    if chars[index] == '%' &&
      index + 2 < chars.length() &&
      is_hex_digit(chars[index + 1]) &&
      is_hex_digit(chars[index + 2]) {
      let high = hex_value(chars[index + 1]).unwrap()
      let low = hex_value(chars[index + 2]).unwrap()
      let byte = (high << 4) | low
      let decoded = byte.unsafe_to_char()
      if byte <= 127 && is_unreserved(decoded) {
        output.push(decoded)
      } else {
        output.push('%')
        output.push(upper_hex_char(chars[index + 1]))
        output.push(upper_hex_char(chars[index + 2]))
      }
      index = index + 3
    } else {
      output.push(chars[index])
      index = index + 1
    }
  }
  chars_to_string(output)
}

///|
fn default_port(scheme : String, port : Int?) -> Int? {
  match (ascii_lower(scheme), port) {
    ("http", Some(80)) => None
    ("https", Some(443)) => None
    ("ws", Some(80)) => None
    ("wss", Some(443)) => None
    ("ftp", Some(21)) => None
    _ => port
  }
}

///|
/// Return the normalized scheme, host and effective port tuple used for
/// same-origin checks.
pub fn UriReference::origin(self : UriReference) -> (String, String, Int?)? {
  match (self.scheme, self.authority) {
    (Some(scheme), Some(authority)) =>
      Some(
        (
          ascii_lower(scheme),
          ascii_lower(authority.host),
          default_port(scheme, authority.port),
        ),
      )
    _ => None
  }
}

///|
pub fn UriReference::same_origin(
  self : UriReference,
  other : UriReference,
) -> Bool {
  match (self.origin(), other.origin()) {
    (Some(left), Some(right)) => left == right
    _ => false
  }
}

///|
/// Normalize case, default ports, percent escapes and dot path segments.
pub fn UriReference::normalize(self : UriReference) -> UriReference {
  let normalized_scheme = self.scheme.map(ascii_lower)
  let normalized_authority = match self.authority {
    Some(authority) => {
      let scheme = match normalized_scheme {
        Some(value) => value
        None => ""
      }
      Some({
        userinfo: authority.userinfo.map(normalize_percent_component),
        host: ascii_lower(authority.host),
        port: default_port(scheme, authority.port),
      })
    }
    None => None
  }
  {
    scheme: normalized_scheme,
    authority: normalized_authority,
    path: normalize_percent_component(normalize_path(self.path)),
    query: self.query.map(normalize_percent_component),
    fragment: self.fragment.map(normalize_percent_component),
  }
}

///|
pub fn normalize_uri(input : String) -> String raise UriError {
  UriReference::parse(input).normalize().to_string()
}

///|
pub fn equivalent_uri(left : String, right : String) -> Bool raise UriError {
  normalize_uri(left) == normalize_uri(right)
}

///|
pub fn UriReference::without_fragment(self : UriReference) -> UriReference {
  {
    scheme: self.scheme,
    authority: self.authority,
    path: self.path,
    query: self.query,
    fragment: None,
  }
}

///|
pub fn UriReference::with_fragment(
  self : UriReference,
  fragment : String?,
) -> UriReference {
  {
    scheme: self.scheme,
    authority: self.authority,
    path: self.path,
    query: self.query,
    fragment,
  }
}

///|
pub fn UriReference::with_query(
  self : UriReference,
  query : String?,
) -> UriReference {
  {
    scheme: self.scheme,
    authority: self.authority,
    path: self.path,
    query,
    fragment: self.fragment,
  }
}

///|
pub fn UriReference::query_params(
  self : UriReference,
) -> QueryParams raise QueryError {
  match self.query {
    Some(value) => QueryParams::parse(value)
    None => QueryParams::new()
  }
}

///|
pub fn UriReference::with_query_params(
  self : UriReference,
  params : QueryParams,
) -> UriReference {
  self.with_query(
    if params.is_empty() {
      None
    } else {
      Some(params.to_rfc3986())
    },
  )
}

///|
pub fn UriReference::path_segments(self : UriReference) -> Array[String] {
  let segments : Array[String] = []
  for segment in uri_split(self.path, '/') {
    if segment != "" {
      segments.push(segment)
    }
  }
  segments
}

///|
pub fn UriReference::decoded_path_segments(
  self : UriReference,
) -> Array[String] raise PercentDecodeError {
  let segments : Array[String] = []
  for segment in self.path_segments() {
    segments.push(percent_decode(segment))
  }
  segments
}

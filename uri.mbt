///|
/// Errors reported while parsing or resolving URI references.
pub suberror UriError {
  InvalidScheme(String)
  InvalidAuthority(String)
  InvalidPort(String)
  RelativeBase(String)
} derive(Debug, Eq)

///|
/// The authority component of a URI reference.
pub struct Authority {
  priv userinfo : String?
  priv host : String
  priv port : Int?
} derive(Debug, Eq)

///|
/// A parsed RFC 3986 URI reference.
pub struct UriReference {
  priv scheme : String?
  priv authority : Authority?
  priv path : String
  priv query : String?
  priv fragment : String?
} derive(Debug, Eq)

///|
fn uri_index_of(chars : Array[Char], needle : Char, start : Int) -> Int {
  for index = start; index < chars.length(); index = index + 1 {
    if chars[index] == needle {
      return index
    }
  }
  -1
}

///|
fn uri_last_index_of(chars : Array[Char], needle : Char) -> Int {
  let mut result = -1
  for index = 0; index < chars.length(); index = index + 1 {
    if chars[index] == needle {
      result = index
    }
  }
  result
}

///|
fn uri_starts_with(text : String, prefix : String) -> Bool {
  let text_chars : Array[Char] = [..text]
  let prefix_chars : Array[Char] = [..prefix]
  if prefix_chars.length() > text_chars.length() {
    return false
  }
  for index = 0; index < prefix_chars.length(); index = index + 1 {
    if text_chars[index] != prefix_chars[index] {
      return false
    }
  }
  true
}

///|
fn uri_ends_with(text : String, suffix : String) -> Bool {
  let text_chars : Array[Char] = [..text]
  let suffix_chars : Array[Char] = [..suffix]
  if suffix_chars.length() > text_chars.length() {
    return false
  }
  let offset = text_chars.length() - suffix_chars.length()
  for index = 0; index < suffix_chars.length(); index = index + 1 {
    if text_chars[offset + index] != suffix_chars[index] {
      return false
    }
  }
  true
}

///|
fn uri_split(text : String, delimiter : Char) -> Array[String] {
  let result : Array[String] = []
  let current : Array[Char] = []
  for c in text {
    if c == delimiter {
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
fn valid_scheme(scheme : String) -> Bool {
  let chars : Array[Char] = [..scheme]
  if chars.length() == 0 ||
    !((chars[0] >= 'A' && chars[0] <= 'Z') ||
    (chars[0] >= 'a' && chars[0] <= 'z')) {
    return false
  }
  for index = 1; index < chars.length(); index = index + 1 {
    let c = chars[index]
    if !(is_alpha_numeric(c) || c == '+' || c == '-' || c == '.') {
      return false
    }
  }
  true
}

///|
fn parse_port(text : String) -> Int raise UriError {
  if text == "" {
    raise InvalidPort(text)
  }
  let mut value = 0
  for c in text {
    if c < '0' || c > '9' {
      raise InvalidPort(text)
    }
    value = value * 10 + (c.to_int() - '0'.to_int())
    if value > 65535 {
      raise InvalidPort(text)
    }
  }
  value
}

///|
fn parse_authority(text : String) -> Authority raise UriError {
  let chars : Array[Char] = [..text]
  let at = uri_last_index_of(chars, '@')
  let userinfo = if at >= 0 { Some(char_slice(chars, 0, at)) } else { None }
  let host_start = if at >= 0 { at + 1 } else { 0 }
  if host_start >= chars.length() {
    raise InvalidAuthority(text)
  }
  if chars[host_start] == '[' {
    let closing = uri_index_of(chars, ']', host_start + 1)
    if closing < 0 {
      raise InvalidAuthority(text)
    }
    let host = char_slice(chars, host_start, closing + 1)
    if closing + 1 == chars.length() {
      return { userinfo, host, port: None, }
    }
    if chars[closing + 1] != ':' {
      raise InvalidAuthority(text)
    }
    let port_text = char_slice(chars, closing + 2, chars.length())
    return { userinfo, host, port: Some(parse_port(port_text)), }
  }
  let colon = uri_last_index_of(chars.map(fn(c) { c }), ':')
  if colon >= host_start {
    let host = char_slice(chars, host_start, colon)
    if host == "" {
      raise InvalidAuthority(text)
    }
    let port_text = char_slice(chars, colon + 1, chars.length())
    { userinfo, host, port: Some(parse_port(port_text)), }
  } else {
    let host = char_slice(chars, host_start, chars.length())
    if host == "" {
      raise InvalidAuthority(text)
    }
    { userinfo, host, port: None, }
  }
}

///|
/// Parse an absolute URI or relative URI reference according to RFC 3986.
pub fn UriReference::parse(input : String) -> UriReference raise UriError {
  let all : Array[Char] = [..input]
  let hash = uri_index_of(all, '#', 0)
  let fragment = if hash >= 0 {
    Some(char_slice(all, hash + 1, all.length()))
  } else {
    None
  }
  let before_fragment_end = if hash >= 0 { hash } else { all.length() }
  let before_fragment = char_slice(all, 0, before_fragment_end)
  let bf : Array[Char] = [..before_fragment]
  let question = uri_index_of(bf, '?', 0)
  let query = if question >= 0 {
    Some(char_slice(bf, question + 1, bf.length()))
  } else {
    None
  }
  let hierarchical_end = if question >= 0 { question } else { bf.length() }
  let hierarchical = char_slice(bf, 0, hierarchical_end)
  let hchars : Array[Char] = [..hierarchical]
  let mut colon = -1
  for index = 0; index < hchars.length(); index = index + 1 {
    if hchars[index] == ':' {
      colon = index
      break
    }
    if hchars[index] == '/' {
      break
    }
  }
  let scheme = if colon >= 0 {
    let candidate = char_slice(hchars, 0, colon)
    if !valid_scheme(candidate) {
      raise InvalidScheme(candidate)
    }
    Some(candidate)
  } else {
    None
  }
  let rest_start = if colon >= 0 { colon + 1 } else { 0 }
  let rest = char_slice(hchars, rest_start, hchars.length())
  if uri_starts_with(rest, "//") {
    let rest_chars : Array[Char] = [..rest]
    let slash = uri_index_of(rest_chars, '/', 2)
    let authority_end = if slash >= 0 { slash } else { rest_chars.length() }
    let authority_text = char_slice(rest_chars, 2, authority_end)
    let path = if slash >= 0 {
      char_slice(rest_chars, slash, rest_chars.length())
    } else {
      ""
    }
    {
      scheme,
      authority: Some(parse_authority(authority_text)),
      path,
      query,
      fragment,
    }
  } else {
    { scheme, authority: None, path: rest, query, fragment, }
  }
}

///|
pub fn Authority::userinfo(self : Authority) -> String? {
  self.userinfo
}

///|
pub fn Authority::host(self : Authority) -> String {
  self.host
}

///|
pub fn Authority::port(self : Authority) -> Int? {
  self.port
}

///|
pub fn Authority::to_string(self : Authority) -> String {
  let user = match self.userinfo {
    Some(value) => value + "@"
    None => ""
  }
  let port = match self.port {
    Some(value) => ":" + value.to_string()
    None => ""
  }
  user + self.host + port
}

///|
pub fn UriReference::scheme(self : UriReference) -> String? {
  self.scheme
}

///|
pub fn UriReference::authority(self : UriReference) -> Authority? {
  self.authority
}

///|
pub fn UriReference::path(self : UriReference) -> String {
  self.path
}

///|
pub fn UriReference::query(self : UriReference) -> String? {
  self.query
}

///|
pub fn UriReference::fragment(self : UriReference) -> String? {
  self.fragment
}

///|
pub fn UriReference::is_absolute(self : UriReference) -> Bool {
  self.scheme is Some(_)
}

///|
pub fn UriReference::has_authority(self : UriReference) -> Bool {
  self.authority is Some(_)
}

///|
pub fn UriReference::to_string(self : UriReference) -> String {
  let scheme = match self.scheme {
    Some(value) => value + ":"
    None => ""
  }
  let authority = match self.authority {
    Some(value) => "//" + value.to_string()
    None => ""
  }
  let query = match self.query {
    Some(value) => "?" + value
    None => ""
  }
  let fragment = match self.fragment {
    Some(value) => "#" + value
    None => ""
  }
  scheme + authority + self.path + query + fragment
}

///|
fn remove_last_segment(segments : Array[String]) -> Unit {
  if segments.length() > 0 {
    segments.pop() |> ignore
  }
}

///|
/// Remove `.` and `..` path segments using the RFC 3986 algorithm.
pub fn normalize_path(path : String) -> String {
  let absolute = uri_starts_with(path, "/")
  let trailing = uri_ends_with(path, "/") ||
    uri_ends_with(path, "/.") ||
    uri_ends_with(path, "/..")
  let output : Array[String] = []
  for segment in uri_split(path, '/') {
    if segment == "" || segment == "." {
      continue
    }
    if segment == ".." {
      remove_last_segment(output)
    } else {
      output.push(segment)
    }
  }
  let body = join(output, "/")
  let prefix = if absolute { "/" } else { "" }
  let suffix = if trailing && body != "" { "/" } else { "" }
  if absolute && body == "" {
    "/"
  } else {
    prefix + body + suffix
  }
}

///|
fn merge_paths(base : UriReference, relative_path : String) -> String {
  if base.authority is Some(_) && base.path == "" {
    return "/" + relative_path
  }
  let chars : Array[Char] = [..base.path]
  let slash = uri_last_index_of(chars, '/')
  if slash >= 0 {
    char_slice(chars, 0, slash + 1) + relative_path
  } else {
    relative_path
  }
}

///|
/// Resolve this URI reference against an absolute base URI.
pub fn UriReference::resolve(
  self : UriReference,
  base : UriReference,
) -> UriReference raise UriError {
  if base.scheme is None {
    raise RelativeBase(base.to_string())
  }
  if self.scheme is Some(_) {
    return {
      scheme: self.scheme,
      authority: self.authority,
      path: normalize_path(self.path),
      query: self.query,
      fragment: self.fragment,
    }
  }
  if self.authority is Some(_) {
    return {
      scheme: base.scheme,
      authority: self.authority,
      path: normalize_path(self.path),
      query: self.query,
      fragment: self.fragment,
    }
  }
  if self.path == "" {
    {
      scheme: base.scheme,
      authority: base.authority,
      path: base.path,
      query: match self.query {
        Some(_) => self.query
        None => base.query
      },
      fragment: self.fragment,
    }
  } else if uri_starts_with(self.path, "/") {
    {
      scheme: base.scheme,
      authority: base.authority,
      path: normalize_path(self.path),
      query: self.query,
      fragment: self.fragment,
    }
  } else {
    {
      scheme: base.scheme,
      authority: base.authority,
      path: normalize_path(merge_paths(base, self.path)),
      query: self.query,
      fragment: self.fragment,
    }
  }
}

///|
/// Parse and resolve a URI reference in one operation.
pub fn resolve_uri(base : String, reference : String) -> String raise UriError {
  let parsed_base = UriReference::parse(base)
  let parsed_reference = UriReference::parse(reference)
  parsed_reference.resolve(parsed_base).to_string()
}

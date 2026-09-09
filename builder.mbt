///|
/// Errors produced by the URI builder.
pub suberror BuilderError {
  EmptyScheme
  EmptyHost
  InvalidBuilderScheme(String)
  InvalidBuilderPort(Int)
} derive(Debug, Eq)

///|
/// A fluent builder for absolute URIs. Path segments and query parameters are
/// encoded independently so delimiters in user input cannot change structure.
pub struct UriBuilder {
  priv scheme : String
  priv mut userinfo : String?
  priv host : String
  priv mut port : Int?
  priv path_segments : Array[String]
  priv mut trailing_slash : Bool
  priv query_params : QueryParams
  priv mut fragment : String?
}

///|
pub fn UriBuilder::new(
  scheme : String,
  host : String,
) -> UriBuilder raise BuilderError {
  if scheme == "" {
    raise EmptyScheme
  }
  if !valid_scheme(scheme) {
    raise InvalidBuilderScheme(scheme)
  }
  if host == "" {
    raise EmptyHost
  }
  {
    scheme,
    userinfo: None,
    host,
    port: None,
    path_segments: [],
    trailing_slash: false,
    query_params: QueryParams::new(),
    fragment: None,
  }
}

///|
pub fn UriBuilder::userinfo(self : UriBuilder, value : String) -> UriBuilder {
  self.userinfo = Some(value)
  self
}

///|
pub fn UriBuilder::clear_userinfo(self : UriBuilder) -> UriBuilder {
  self.userinfo = None
  self
}

///|
pub fn UriBuilder::port(
  self : UriBuilder,
  value : Int,
) -> UriBuilder raise BuilderError {
  if value < 0 || value > 65535 {
    raise InvalidBuilderPort(value)
  }
  self.port = Some(value)
  self
}

///|
pub fn UriBuilder::clear_port(self : UriBuilder) -> UriBuilder {
  self.port = None
  self
}

///|
pub fn UriBuilder::push_path(self : UriBuilder, segment : String) -> UriBuilder {
  self.path_segments.push(segment)
  self
}

///|
pub fn UriBuilder::push_paths(
  self : UriBuilder,
  segments : Array[String],
) -> UriBuilder {
  for segment in segments {
    self.path_segments.push(segment)
  }
  self
}

///|
pub fn UriBuilder::pop_path(self : UriBuilder) -> String? {
  self.path_segments.pop()
}

///|
pub fn UriBuilder::clear_path(self : UriBuilder) -> UriBuilder {
  self.path_segments.clear()
  self
}

///|
pub fn UriBuilder::trailing_slash(
  self : UriBuilder,
  enabled : Bool,
) -> UriBuilder {
  self.trailing_slash = enabled
  self
}

///|
pub fn UriBuilder::add_query(
  self : UriBuilder,
  key : String,
  value : String,
) -> UriBuilder {
  self.query_params.add(key, value) |> ignore
  self
}

///|
pub fn UriBuilder::set_query(
  self : UriBuilder,
  key : String,
  value : String,
) -> UriBuilder {
  self.query_params.set(key, value) |> ignore
  self
}

///|
pub fn UriBuilder::remove_query(self : UriBuilder, key : String) -> UriBuilder {
  self.query_params.remove(key) |> ignore
  self
}

///|
pub fn UriBuilder::fragment(self : UriBuilder, value : String) -> UriBuilder {
  self.fragment = Some(value)
  self
}

///|
pub fn UriBuilder::clear_fragment(self : UriBuilder) -> UriBuilder {
  self.fragment = None
  self
}

///|
fn encode_path_segment(segment : String) -> String {
  encode(segment)
}

///|
fn UriBuilder::builder_path(self : UriBuilder) -> String {
  if self.path_segments.length() == 0 {
    if self.trailing_slash {
      "/"
    } else {
      ""
    }
  } else {
    let encoded = self.path_segments.map(encode_path_segment)
    let suffix = if self.trailing_slash { "/" } else { "" }
    "/" + join(encoded, "/") + suffix
  }
}

///|
pub fn UriBuilder::to_string(self : UriBuilder) -> String {
  let userinfo = match self.userinfo {
    Some(value) => encode(value) + "@"
    None => ""
  }
  let port = match self.port {
    Some(value) => ":" + value.to_string()
    None => ""
  }
  let query = if self.query_params.is_empty() {
    ""
  } else {
    "?" + self.query_params.to_rfc3986()
  }
  let fragment = match self.fragment {
    Some(value) => "#" + encode(value, allow_reserved=true)
    None => ""
  }
  self.scheme +
  "://" +
  userinfo +
  self.host +
  port +
  self.builder_path() +
  query +
  fragment
}

///|
pub fn UriBuilder::build(self : UriBuilder) -> UriReference raise UriError {
  UriReference::parse(self.to_string())
}

///|
pub suberror PolicyError {
  InputTooLong(Int, Int)
  RelativeReferenceForbidden
  AuthorityRequired
  SchemeForbidden(String)
  UserinfoForbidden
  FragmentForbidden
  PortForbidden(Int)
} derive(Debug, Eq)

///|
/// Configurable structural validation for application-supplied URI values.
pub struct UriPolicy {
  priv allowed_schemes : Array[String]
  priv allowed_ports : Array[Int]
  priv mut allow_relative : Bool
  priv mut require_authority : Bool
  priv mut allow_userinfo : Bool
  priv mut allow_fragment : Bool
  priv mut max_length : Int
}

///|
/// Create a web-oriented policy allowing HTTP and HTTPS absolute URIs.
pub fn UriPolicy::web() -> UriPolicy {
  {
    allowed_schemes: ["http", "https"],
    allowed_ports: [],
    allow_relative: false,
    require_authority: true,
    allow_userinfo: false,
    allow_fragment: true,
    max_length: 8192,
  }
}

///|
/// Create a policy with no scheme restriction and relative references enabled.
pub fn UriPolicy::permissive() -> UriPolicy {
  {
    allowed_schemes: [],
    allowed_ports: [],
    allow_relative: true,
    require_authority: false,
    allow_userinfo: true,
    allow_fragment: true,
    max_length: 65536,
  }
}

///|
pub fn UriPolicy::schemes(
  self : UriPolicy,
  schemes : Array[String],
) -> UriPolicy {
  self.allowed_schemes.clear()
  for scheme in schemes {
    self.allowed_schemes.push(ascii_lower(scheme))
  }
  self
}

///|
pub fn UriPolicy::ports(self : UriPolicy, ports : Array[Int]) -> UriPolicy {
  self.allowed_ports.clear()
  for port in ports {
    self.allowed_ports.push(port)
  }
  self
}

///|
pub fn UriPolicy::relative(self : UriPolicy, allowed : Bool) -> UriPolicy {
  self.allow_relative = allowed
  self
}

///|
pub fn UriPolicy::authority(self : UriPolicy, required : Bool) -> UriPolicy {
  self.require_authority = required
  self
}

///|
pub fn UriPolicy::userinfo(self : UriPolicy, allowed : Bool) -> UriPolicy {
  self.allow_userinfo = allowed
  self
}

///|
pub fn UriPolicy::fragment(self : UriPolicy, allowed : Bool) -> UriPolicy {
  self.allow_fragment = allowed
  self
}

///|
pub fn UriPolicy::max_length(self : UriPolicy, length : Int) -> UriPolicy {
  self.max_length = length
  self
}

///|
fn string_in(values : Array[String], expected : String) -> Bool {
  for value in values {
    if value == expected {
      return true
    }
  }
  false
}

///|
fn int_in(values : Array[Int], expected : Int) -> Bool {
  for value in values {
    if value == expected {
      return true
    }
  }
  false
}

///|
pub fn UriPolicy::validate(
  self : UriPolicy,
  uri : UriReference,
) -> Unit raise PolicyError {
  let serialized = uri.to_string()
  if serialized.length() > self.max_length {
    raise InputTooLong(serialized.length(), self.max_length)
  }
  match uri.scheme {
    Some(scheme) =>
      if self.allowed_schemes.length() > 0 &&
        !string_in(self.allowed_schemes, ascii_lower(scheme)) {
        raise SchemeForbidden(scheme)
      }
    None => if !self.allow_relative { raise RelativeReferenceForbidden }
  }
  if self.require_authority && uri.authority is None {
    raise AuthorityRequired
  }
  match uri.authority {
    Some(authority) => {
      if !self.allow_userinfo && authority.userinfo is Some(_) {
        raise UserinfoForbidden
      }
      match authority.port {
        Some(port) =>
          if self.allowed_ports.length() > 0 &&
            !int_in(self.allowed_ports, port) {
            raise PortForbidden(port)
          }
        None => ()
      }
    }
    None => ()
  }
  if !self.allow_fragment && uri.fragment is Some(_) {
    raise FragmentForbidden
  }
}

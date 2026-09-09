///|
pub suberror RouteError {
  RouteMustStartWithSlash(String)
  EmptyRouteParameter(Int)
  InvalidRouteParameter(String)
  DuplicateRouteParameter(String)
  CatchAllMustBeLast(String)
  MissingRouteValue(String)
} derive(Debug, Eq)

///|
priv enum RoutePart {
  StaticPart(String)
  ParameterPart(String)
  CatchAllPart(String)
}

///|
/// A parsed path route such as `/users/{id}/files/{*path}`.
pub struct RoutePattern {
  priv source : String
  priv parts : Array[RoutePart]
}

///|
/// Values captured while matching a route pattern.
pub struct RouteMatch {
  priv values : Map[String, String]
}

///|
fn route_parameter_name(segment : String) -> (String, Bool)? {
  let chars : Array[Char] = [..segment]
  if chars.length() < 2 || chars[0] != '{' || chars[chars.length() - 1] != '}' {
    return None
  }
  let catch_all = chars.length() > 2 && chars[1] == '*'
  let start = if catch_all { 2 } else { 1 }
  Some((char_slice(chars, start, chars.length() - 1), catch_all))
}

///|
fn valid_route_name(name : String) -> Bool {
  if name == "" {
    return false
  }
  for c in name {
    if !(is_alpha_numeric(c) || c == '_') {
      return false
    }
  }
  true
}

///|
pub fn RoutePattern::parse(source : String) -> RoutePattern raise RouteError {
  if !uri_starts_with(source, "/") {
    raise RouteMustStartWithSlash(source)
  }
  let raw = uri_split(source, '/')
  let parts : Array[RoutePart] = []
  let names : Array[String] = []
  for index = 1; index < raw.length(); index = index + 1 {
    let segment = raw[index]
    match route_parameter_name(segment) {
      Some((name, catch_all)) => {
        if name == "" {
          raise EmptyRouteParameter(index - 1)
        }
        if !valid_route_name(name) {
          raise InvalidRouteParameter(name)
        }
        for existing in names {
          if existing == name {
            raise DuplicateRouteParameter(name)
          }
        }
        names.push(name)
        if catch_all {
          if index != raw.length() - 1 {
            raise CatchAllMustBeLast(name)
          }
          parts.push(CatchAllPart(name))
        } else {
          parts.push(ParameterPart(name))
        }
      }
      None => {
        if uri_starts_with(segment, "{") || uri_ends_with(segment, "}") {
          raise InvalidRouteParameter(segment)
        }
        parts.push(StaticPart(segment))
      }
    }
  }
  { source, parts, }
}

///|
pub fn RoutePattern::source(self : RoutePattern) -> String {
  self.source
}

///|
pub fn RoutePattern::parameter_names(self : RoutePattern) -> Array[String] {
  let names : Array[String] = []
  for part in self.parts {
    match part {
      ParameterPart(name) | CatchAllPart(name) => names.push(name)
      StaticPart(_) => ()
    }
  }
  names
}

///|
fn remaining_path(segments : Array[String], start : Int) -> String {
  let remaining : Array[String] = []
  for index = start; index < segments.length(); index = index + 1 {
    remaining.push(segments[index])
  }
  join(remaining, "/")
}

///|
/// Match a URL path. Captured values are percent-decoded.
pub fn RoutePattern::match_path(
  self : RoutePattern,
  path : String,
) -> RouteMatch? raise PercentDecodeError {
  let raw = uri_split(path, '/')
  let segments : Array[String] = []
  let start = if raw.length() > 0 && raw[0] == "" { 1 } else { 0 }
  for index = start; index < raw.length(); index = index + 1 {
    segments.push(raw[index])
  }
  let values : Map[String, String] = Map([])
  let mut cursor = 0
  for part in self.parts {
    match part {
      StaticPart(expected) => {
        if cursor >= segments.length() || segments[cursor] != expected {
          return None
        }
        cursor = cursor + 1
      }
      ParameterPart(name) => {
        if cursor >= segments.length() {
          return None
        }
        values.set(name, percent_decode(segments[cursor]))
        cursor = cursor + 1
      }
      CatchAllPart(name) => {
        let captured = remaining_path(segments, cursor)
        values.set(name, percent_decode(captured))
        cursor = segments.length()
      }
    }
  }
  if cursor != segments.length() {
    None
  } else {
    Some({ values, })
  }
}

///|
pub fn RoutePattern::match_uri(
  self : RoutePattern,
  uri : UriReference,
) -> RouteMatch? raise PercentDecodeError {
  self.match_path(uri.path())
}

///|
pub fn RouteMatch::get(self : RouteMatch, name : String) -> String? {
  self.values.get(name)
}

///|
pub fn RouteMatch::contains(self : RouteMatch, name : String) -> Bool {
  self.values.get(name) is Some(_)
}

///|
pub fn RouteMatch::length(self : RouteMatch) -> Int {
  self.values.length()
}

///|
/// Render a path using named values. Each value is encoded as a path segment;
/// catch-all values preserve `/` separators while encoding each segment.
pub fn RoutePattern::render(
  self : RoutePattern,
  values : Map[String, String],
) -> String raise RouteError {
  let output : Array[String] = []
  for part in self.parts {
    match part {
      StaticPart(value) => output.push(value)
      ParameterPart(name) =>
        match values.get(name) {
          Some(value) => output.push(encode(value))
          None => raise MissingRouteValue(name)
        }
      CatchAllPart(name) =>
        match values.get(name) {
          Some(value) => {
            let encoded = uri_split(value, '/').map(encode_path_segment)
            output.push(join(encoded, "/"))
          }
          None => raise MissingRouteValue(name)
        }
    }
  }
  "/" + join(output, "/")
}

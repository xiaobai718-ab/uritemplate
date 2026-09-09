///|
/// Return the last non-empty path segment, without percent-decoding it.
pub fn UriReference::filename(self : UriReference) -> String? {
  let segments = self.path_segments()
  if segments.length() == 0 {
    None
  } else {
    Some(segments[segments.length() - 1])
  }
}

///|
/// Return the suffix after the final dot in the filename.
pub fn UriReference::extension(self : UriReference) -> String? {
  match self.filename() {
    Some(filename) => {
      let chars : Array[Char] = [..filename]
      let dot = uri_last_index_of(chars, '.')
      if dot <= 0 || dot == chars.length() - 1 {
        None
      } else {
        Some(char_slice(chars, dot + 1, chars.length()))
      }
    }
    None => None
  }
}

///|
/// Return the effective port, including the conventional default when absent.
pub fn UriReference::effective_port(self : UriReference) -> Int? {
  match self.authority {
    Some(authority) =>
      match authority.port {
        Some(port) => Some(port)
        None =>
          match self.scheme.map(ascii_lower) {
            Some("http") | Some("ws") => Some(80)
            Some("https") | Some("wss") => Some(443)
            Some("ftp") => Some(21)
            _ => None
          }
      }
    None => None
  }
}

///|
pub fn UriReference::is_secure_transport(self : UriReference) -> Bool {
  match self.scheme.map(ascii_lower) {
    Some("https") | Some("wss") => true
    _ => false
  }
}

///|
/// Replace the path while retaining scheme, authority, query and fragment.
pub fn UriReference::with_path(
  self : UriReference,
  path : String,
) -> UriReference {
  {
    scheme: self.scheme,
    authority: self.authority,
    path,
    query: self.query,
    fragment: self.fragment,
  }
}

///|
/// Append one encoded path segment before the query and fragment.
pub fn UriReference::append_path_segment(
  self : UriReference,
  segment : String,
) -> UriReference {
  let separator = if self.path == "" || uri_ends_with(self.path, "/") {
    ""
  } else {
    "/"
  }
  let prefix = if self.path == "" && self.authority is Some(_) {
    "/"
  } else {
    ""
  }
  self.with_path(self.path + prefix + separator + encode_path_segment(segment))
}

///|
/// Return the URI containing the parent path and no query or fragment.
pub fn UriReference::parent(self : UriReference) -> UriReference {
  let chars : Array[Char] = [..self.path]
  let mut end = chars.length()
  while end > 1 && chars[end - 1] == '/' {
    end = end - 1
  }
  let truncated = char_slice(chars, 0, end)
  let slash = uri_last_index_of([..truncated], '/')
  let parent_path = if slash < 0 {
    ""
  } else if slash == 0 {
    "/"
  } else {
    char_slice([..truncated], 0, slash)
  }
  {
    scheme: self.scheme,
    authority: self.authority,
    path: parent_path,
    query: None,
    fragment: None,
  }
}

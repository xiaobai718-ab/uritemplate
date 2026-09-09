///|
pub suberror PercentDecodeError {
  IncompleteEscape(Int)
  InvalidEscape(Int, String)
  InvalidUtf8
} derive(Debug, Eq)

///|
fn hex_value(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
fn append_utf8_bytes(output : Array[Byte], c : Char) -> Unit {
  let encoded = @utf8.encode(chars_to_string([c]))
  for byte in encoded {
    output.push(byte)
  }
}

///|
/// Decode RFC 3986 percent escapes. Optionally decode `+` as a space for
/// HTML form compatibility.
pub fn percent_decode(
  input : String,
  plus_as_space? : Bool = false,
) -> String raise PercentDecodeError {
  let chars : Array[Char] = [..input]
  let bytes : Array[Byte] = []
  let mut index = 0
  while index < chars.length() {
    let c = chars[index]
    if c == '%' {
      if index + 2 >= chars.length() {
        raise IncompleteEscape(index)
      }
      match (hex_value(chars[index + 1]), hex_value(chars[index + 2])) {
        (Some(high), Some(low)) => bytes.push(((high << 4) | low).to_byte())
        _ =>
          raise InvalidEscape(
            index,
            chars_to_string([chars[index], chars[index + 1], chars[index + 2]]),
          )
      }
      index = index + 3
    } else {
      append_utf8_bytes(bytes, if plus_as_space && c == '+' { ' ' } else { c })
      index = index + 1
    }
  }
  @utf8.decode(Bytes::from_array(bytes)) catch {
    _ => raise InvalidUtf8
  }
}

///|
/// Encode an HTML form query component, representing spaces as `+`.
pub fn form_encode(input : String) -> String {
  let encoded = encode(input)
  let output : Array[Char] = []
  let chars : Array[Char] = [..encoded]
  let mut index = 0
  while index < chars.length() {
    if index + 2 < chars.length() &&
      chars[index] == '%' &&
      chars[index + 1] == '2' &&
      chars[index + 2] == '0' {
      output.push('+')
      index = index + 3
    } else {
      output.push(chars[index])
      index = index + 1
    }
  }
  chars_to_string(output)
}

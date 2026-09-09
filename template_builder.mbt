///|
/// Public operator names for programmatic URI Template construction.
pub(all) enum TemplateOperator {
  Simple
  Reserved
  Fragment
  Label
  Path
  Matrix
  Query
  Continuation
} derive(Debug, Eq)

///|
pub suberror TemplateBuildError {
  EmptyVariableName
  InvalidBuilderVariable(String)
  InvalidPrefixLength(Int)
  ConflictingModifiers(String)
  EmptyVariableList
  BraceInLiteral(String)
} derive(Debug, Eq)

///|
/// A variable reference used to construct a template expression.
pub struct VariableRef {
  priv name : String
  priv explode : Bool
  priv prefix : Int?
}

///|
/// A builder that produces a validated `Template` without handwritten braces
/// or comma-separated variable specifications.
pub struct TemplateBuilder {
  priv pieces : Array[String]
}

///|
pub fn VariableRef::new(name : String) -> VariableRef raise TemplateBuildError {
  if name == "" {
    raise EmptyVariableName
  }
  for c in name {
    if !valid_var_char(c) {
      raise InvalidBuilderVariable(name)
    }
  }
  { name, explode: false, prefix: None, }
}

///|
pub fn VariableRef::explode(
  self : VariableRef,
) -> VariableRef raise TemplateBuildError {
  if self.prefix is Some(_) {
    raise ConflictingModifiers(self.name)
  }
  { name: self.name, explode: true, prefix: None, }
}

///|
pub fn VariableRef::prefix(
  self : VariableRef,
  length : Int,
) -> VariableRef raise TemplateBuildError {
  if length <= 0 {
    raise InvalidPrefixLength(length)
  }
  if self.explode {
    raise ConflictingModifiers(self.name)
  }
  { name: self.name, explode: false, prefix: Some(length), }
}

///|
pub fn VariableRef::name(self : VariableRef) -> String {
  self.name
}

///|
pub fn VariableRef::is_exploded(self : VariableRef) -> Bool {
  self.explode
}

///|
pub fn VariableRef::prefix_length(self : VariableRef) -> Int? {
  self.prefix
}

///|
fn VariableRef::to_varspec(self : VariableRef) -> String {
  if self.explode {
    self.name + "*"
  } else {
    match self.prefix {
      Some(value) => self.name + ":" + value.to_string()
      None => self.name
    }
  }
}

///|
fn template_operator_symbol(operator : TemplateOperator) -> String {
  match operator {
    Simple => ""
    Reserved => "+"
    Fragment => "#"
    Label => "."
    Path => "/"
    Matrix => ";"
    Query => "?"
    Continuation => "&"
  }
}

///|
pub fn TemplateBuilder::new() -> TemplateBuilder {
  { pieces: [], }
}

///|
/// Append literal URI text. Braces are rejected because they would be
/// interpreted as an expression by RFC 6570.
pub fn TemplateBuilder::literal(
  self : TemplateBuilder,
  text : String,
) -> TemplateBuilder raise TemplateBuildError {
  for c in text {
    if c == '{' || c == '}' {
      raise BraceInLiteral(text)
    }
  }
  self.pieces.push(text)
  self
}

///|
pub fn TemplateBuilder::expression(
  self : TemplateBuilder,
  operator : TemplateOperator,
  variables : Array[VariableRef],
) -> TemplateBuilder raise TemplateBuildError {
  if variables.length() == 0 {
    raise EmptyVariableList
  }
  let specs = variables.map(fn(variable) { variable.to_varspec() })
  self.pieces.push(
    "{" + template_operator_symbol(operator) + join(specs, ",") + "}",
  )
  self
}

///|
pub fn TemplateBuilder::simple(
  self : TemplateBuilder,
  name : String,
) -> TemplateBuilder raise TemplateBuildError {
  self.expression(Simple, [VariableRef::new(name)])
}

///|
pub fn TemplateBuilder::path(
  self : TemplateBuilder,
  names : Array[String],
) -> TemplateBuilder raise TemplateBuildError {
  let variables : Array[VariableRef] = []
  for name in names {
    variables.push(VariableRef::new(name))
  }
  self.expression(Path, variables)
}

///|
pub fn TemplateBuilder::query(
  self : TemplateBuilder,
  names : Array[String],
) -> TemplateBuilder raise TemplateBuildError {
  let variables : Array[VariableRef] = []
  for name in names {
    variables.push(VariableRef::new(name))
  }
  self.expression(Query, variables)
}

///|
pub fn TemplateBuilder::source(self : TemplateBuilder) -> String {
  join(self.pieces, "")
}

///|
pub fn TemplateBuilder::build(
  self : TemplateBuilder,
) -> Template raise ExpandError {
  Template::parse(self.source())
}

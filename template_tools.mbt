///|
/// Metadata about one variable referenced by a URI Template.
pub struct TemplateVariable {
  priv name : String
  priv operator : String
  priv explode : Bool
  priv prefix : Int?
}

///|
pub suberror BindingError {
  MissingBindings(Array[String])
} derive(Debug, Eq)

///|
pub fn TemplateVariable::name(self : TemplateVariable) -> String {
  self.name
}

///|
pub fn TemplateVariable::operator(self : TemplateVariable) -> String {
  self.operator
}

///|
pub fn TemplateVariable::explode(self : TemplateVariable) -> Bool {
  self.explode
}

///|
pub fn TemplateVariable::prefix(self : TemplateVariable) -> Int? {
  self.prefix
}

///|
fn operator_name(op : Operator) -> String {
  if op.prefix == "#" {
    "#"
  } else if op.prefix == "." {
    "."
  } else if op.prefix == "/" {
    "/"
  } else if op.prefix == ";" {
    ";"
  } else if op.prefix == "?" {
    "?"
  } else if op.prefix == "&" {
    "&"
  } else if op.allow_reserved {
    "+"
  } else {
    ""
  }
}

///|
/// Return every variable occurrence in template order.
pub fn Template::variables(self : Template) -> Array[TemplateVariable] {
  let variables : Array[TemplateVariable] = []
  for part in self.parts {
    match part {
      Literal(_) => ()
      Expression(op, specs) =>
        for spec in specs {
          variables.push({
            name: spec.name,
            operator: operator_name(op),
            explode: spec.explode,
            prefix: spec.prefix,
          })
        }
    }
  }
  variables
}

///|
/// Return variable names once each, preserving first appearance order.
pub fn Template::variable_names(self : Template) -> Array[String] {
  let names : Array[String] = []
  for variable in self.variables() {
    let mut found = false
    for existing in names {
      if existing == variable.name {
        found = true
      }
    }
    if !found {
      names.push(variable.name)
    }
  }
  names
}

///|
pub fn Bindings::contains(self : Bindings, name : String) -> Bool {
  self.values.get(name) is Some(_)
}

///|
pub fn Bindings::length(self : Bindings) -> Int {
  self.values.length()
}

///|
pub fn Bindings::remove(self : Bindings, name : String) -> Bindings {
  self.values.remove(name) |> ignore
  self
}

///|
pub fn Template::missing_variables(
  self : Template,
  bindings : Bindings,
) -> Array[String] {
  let missing : Array[String] = []
  for name in self.variable_names() {
    if !bindings.contains(name) {
      missing.push(name)
    }
  }
  missing
}

///|
/// Expand only when every variable named by the template has a binding.
pub fn Template::expand_checked(
  self : Template,
  bindings : Bindings,
) -> String raise BindingError {
  let missing = self.missing_variables(bindings)
  if missing.length() > 0 {
    raise MissingBindings(missing)
  }
  self.expand(bindings)
}

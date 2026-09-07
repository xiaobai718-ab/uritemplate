///|
fn main {
  let values = @uritemplate.Bindings::new()
    .set_string("owner", "moonbitlang")
    .set_string("repo", "core")
    .set_list("labels", ["good first issue", "help wanted"])
  let url = @uritemplate.expand(
    "https://api.github.com/repos{/owner,repo}/issues{?labels*}", values,
  ) catch {
    _ => abort("invalid URI template")
  }
  println(url)
}

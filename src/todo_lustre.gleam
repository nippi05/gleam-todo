import lustre
import lustre/attribute
import lustre/element/html

pub fn main() {
  let app =
    lustre.element(
      html.div([], [
        html.header([], [
          html.nav([], [
            html.a([attribute.href("#")], [html.text("Sign In")]),
            html.a([attribute.href("#")], [html.text("Sign up")]),
          ]),
        ]),
        html.main([], [
          html.h1([], [html.text("Todo")]),
          html.form(
            [
              attribute.action("add-todo"),
              attribute.method("post"),
              attribute.class("add-todo"),
            ],
            [
              html.input([
                attribute.type_("text"),
                attribute.name("task-name"),
                attribute.id("task-name"),
                attribute.placeholder("Task name"),
              ]),
              html.input([
                attribute.type_("submit"),
                attribute.value("Add todo!"),
              ]),
            ],
          ),
          html.ul([], [
            html.li([], [
              html.input([attribute.type_("checkbox")]),
              html.p([], [html.text("Placeholder task")]),
              html.p([], [html.text("Placeholder name")]),
            ]),
          ]),
        ]),
        html.footer([], [
          html.p([], [
            html.text(
              "A short footer containing some information, for instance a copyright to FooCorp",
            ),
          ]),
        ]),
      ]),
    )
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type TodoId =
  Int

// TODO: Change this
pub type User =
  String

pub type Todo {
  Todo(id: TodoId, done: Bool, creator: User, content: String)
}

// pub type PopUpState {
//   None
//   Login
//   SignUp
// }

pub type Model {
  Model(
    todos: List(Todo),
    current_todo_content: String,
    next_todo_id: Int,
    local_user: User,
  )
}

fn init(_flags) -> Model {
  Model([], "", 1, "anonymous")
}

pub type Msg {
  UserAddedTodo
  UserRemovedTodo(id: TodoId)
  UserToggledTodo(id: TodoId)
  UserUpdatedCurrentTodoContent(new_content: String)
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UserAddedTodo -> {
      case model.current_todo_content == "" {
        True -> model
        False -> {
          let todo_ =
            Todo(
              id: model.next_todo_id,
              done: False,
              creator: model.local_user,
              content: model.current_todo_content,
            )
          Model(
            ..model,
            todos: model.todos |> list.append([todo_]),
            next_todo_id: model.next_todo_id + 1,
            current_todo_content: "",
          )
        }
      }
    }
    UserRemovedTodo(id) ->
      Model(
        ..model,
        todos: model.todos |> list.filter(fn(todo_) { todo_.id != id }),
      )
    UserToggledTodo(id) ->
      Model(
        ..model,
        todos: model.todos
          |> list.map(fn(todo_) {
            case todo_.id == id {
              True -> Todo(..todo_, done: !todo_.done)
              False -> todo_
            }
          }),
      )
    UserUpdatedCurrentTodoContent(new_content) ->
      Model(..model, current_todo_content: new_content)
  }
}

pub fn view(model: Model) -> element.Element(Msg) {
  let todos_lis =
    model.todos
    |> list.map(fn(todo_) {
      html.li([], [
        html.input([
          attribute.type_("checkbox"),
          attribute.checked(todo_.done),
          event.on_check(fn(_) { UserToggledTodo(todo_.id) }),
        ]),
        html.p([], [html.text(int.to_string(todo_.id))]),
        html.p([], [html.text(todo_.content)]),
        html.p([], [html.text(todo_.creator)]),
      ])
    })

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
          event.on_submit(UserAddedTodo),
        ],
        [
          html.input([
            attribute.type_("text"),
            attribute.name("task-name"),
            attribute.id("task-name"),
            attribute.placeholder("Task name"),
            event.on_input(fn(str) { UserUpdatedCurrentTodoContent(str) }),
            attribute.value(model.current_todo_content),
          ]),
          html.input([attribute.type_("submit"), attribute.value("Add todo!")]),
        ],
      ),
      html.ul([], todos_lis),
    ]),
    html.footer([], [
      html.p([], [
        html.text(
          "A short footer containing some information, for instance a copyright to FooCorp",
        ),
      ]),
    ]),
  ])
}

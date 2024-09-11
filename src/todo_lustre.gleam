import gleam/int
import gleam/list
import gleam/option
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
  Todo(id: TodoId, done: Bool, creator: option.Option(User), content: String)
}

pub type PopUpState {
  None
  Login(username: String, password: String)
  SignUp(username: String, password: String)
}

pub type Model {
  Model(
    todos: List(Todo),
    current_todo_content: String,
    next_todo_id: Int,
    local_user: option.Option(User),
    popup_state: PopUpState,
  )
}

fn init(_flags) -> Model {
  Model([], "", 1, option.None, None)
}

pub type Msg {
  UserAddedTodo
  UserRemovedTodo(id: TodoId)
  UserToggledTodo(id: TodoId)
  UserUpdatedCurrentTodoContent(new_content: String)
  UserUpdatedPopUpState(new_state: PopUpState)
  UserUpdatedPopUpUsername(new_username: String)
  UserUpdatedPopUpPassword(new_password: String)
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

    UserUpdatedPopUpState(new_state) ->
      case model.popup_state, new_state {
        // TODO: Send network request here to verify login or signup
        Login(username, password), None ->
          Model(..model, popup_state: new_state)
        SignUp(username, password), None ->
          Model(..model, popup_state: new_state)
        _, _ -> Model(..model, popup_state: new_state)
      }
    UserUpdatedPopUpUsername(new_username) ->
      case model.popup_state {
        None -> model
        Login(_, password) ->
          Model(
            ..model,
            popup_state: Login(username: new_username, password: password),
          )
        SignUp(_, password) ->
          Model(
            ..model,
            popup_state: Login(username: new_username, password: password),
          )
      }

    UserUpdatedPopUpPassword(new_password) ->
      case model.popup_state {
        None -> model
        Login(username, _) ->
          Model(
            ..model,
            popup_state: Login(username: username, password: new_password),
          )
        SignUp(username, _) ->
          Model(
            ..model,
            popup_state: Login(username: username, password: new_password),
          )
      }
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
        html.p([], [
          html.text(case todo_.creator {
            option.Some(creator) -> creator
            option.None -> "Anonymous"
          }),
        ]),
      ])
    })

  let login_signup_form = fn(submit_button_value, username, password) {
    html.form([event.on_submit(UserUpdatedPopUpState(None))], [
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Username"),
        attribute.value(username),
        event.on_input(fn(new_username) {
          UserUpdatedPopUpUsername(new_username)
        }),
      ]),
      html.input([
        attribute.type_("text"),
        attribute.placeholder("Password"),
        attribute.value(password),
        event.on_input(fn(new_password) {
          UserUpdatedPopUpPassword(new_password)
        }),
      ]),
      html.input([
        attribute.type_("submit"),
        attribute.value(submit_button_value),
      ]),
    ])
  }

  html.div([], [
    html.header([], [
      html.nav([], case model.local_user {
        option.None -> [
          html.button(
            [
              event.on_click(
                UserUpdatedPopUpState(Login(username: "", password: "")),
              ),
            ],
            [html.text("Login")],
          ),
          html.button(
            [
              event.on_click(
                UserUpdatedPopUpState(SignUp(username: "", password: "")),
              ),
            ],
            [html.text("Sign Up")],
          ),
        ]
        option.Some(user) -> [html.text(user)]
      }),
    ]),
    html.main([], [
      case model.popup_state {
        None -> element.none()
        Login(username, password) ->
          login_signup_form("Login", username, password)
        SignUp(username, password) ->
          login_signup_form("Sign Up", username, password)
      },
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

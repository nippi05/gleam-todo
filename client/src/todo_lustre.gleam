import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http as http
import shared.{type User}

// TODO: Make this https? and a real server
const server_url = "http://localhost:8000"

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type TodoId =
  Int

pub type Todo {
  Todo(id: TodoId, done: Bool, creator: Option(User), content: String)
}

pub type LoginPopUp {
  Login(username: String, password: String)
  SignUp(username: String, password: String)
  Loading
}

pub type Model {
  Model(
    todos: List(Todo),
    current_todo_input_content: String,
    next_todo_id: Int,
    local_user: Option(User),
    auth_token: Option(String),
    login_popup: Option(LoginPopUp),
  )
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      todos: [],
      current_todo_input_content: "",
      next_todo_id: 1,
      local_user: None,
      auth_token: None,
      login_popup: None,
    ),
    effect.none(),
  )
}

pub type Msg {
  UserAddedTodo
  UserRemovedTodo(id: TodoId)
  UserToggledTodo(id: TodoId)
  UserUpdatedCurrentTodoContent(new_content: String)
  UserRequestedNewLoginPopUp(requested_state: Option(LoginPopUp))
  UserUpdatedPopUpUsername(new_username: String)
  UserUpdatedPopUpPassword(new_password: String)
  ApiRetunedLoginAttempt(Result(shared.LoginAttemptResponse, http.HttpError))
}

fn send_login(username: String, password: String) -> effect.Effect(Msg) {
  let expect =
    http.expect_json(
      shared.decode_login_attempt_response,
      ApiRetunedLoginAttempt,
    )

  let body =
    json.object([
      #("username", json.string(username)),
      #("password", json.string(password)),
    ])

  http.post(server_url, body, expect)
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserAddedTodo -> {
      #(
        case model.current_todo_input_content == "" {
          True -> model
          False -> {
            let todo_ =
              Todo(
                id: model.next_todo_id,
                done: False,
                creator: model.local_user,
                content: model.current_todo_input_content,
              )
            Model(
              ..model,
              todos: model.todos |> list.append([todo_]),
              next_todo_id: model.next_todo_id + 1,
              current_todo_input_content: "",
            )
          }
        },
        effect.none(),
      )
    }
    UserRemovedTodo(id) -> #(
      Model(
        ..model,
        todos: model.todos |> list.filter(fn(todo_) { todo_.id != id }),
      ),
      effect.none(),
    )
    UserToggledTodo(id) -> #(
      Model(
        ..model,
        todos: model.todos
          |> list.map(fn(todo_) {
            case todo_.id == id {
              True -> Todo(..todo_, done: !todo_.done)
              False -> todo_
            }
          }),
      ),
      effect.none(),
    )
    UserUpdatedCurrentTodoContent(new_content) -> #(
      Model(..model, current_todo_input_content: new_content),
      effect.none(),
    )

    UserRequestedNewLoginPopUp(requested_state) ->
      case model.login_popup, requested_state {
        None, Some(_) -> #(
          Model(..model, login_popup: requested_state),
          effect.none(),
        )

        Some(Login(username, password)), None -> {
          #(
            Model(..model, login_popup: Some(Loading)),
            send_login(username, password),
          )
        }
        Some(SignUp(username, password)), None -> {
          #(
            Model(..model, login_popup: Some(Loading)),
            send_login(username, password),
            // TODO: Change this to send signup
          )
        }
        _, _ -> #(
          Model(..io.debug(model), login_popup: io.debug(requested_state)),
          effect.none(),
        )
      }
    UserUpdatedPopUpUsername(new_username) -> #(
      case model.login_popup {
        None -> model
        Some(Loading) -> model
        Some(Login(_, password)) ->
          Model(
            ..model,
            login_popup: Some(Login(username: new_username, password: password)),
          )
        Some(SignUp(_, password)) ->
          Model(
            ..model,
            login_popup: Some(Login(username: new_username, password: password)),
          )
      },
      effect.none(),
    )

    UserUpdatedPopUpPassword(new_password) -> #(
      case model.login_popup {
        None -> model
        Some(Loading) -> model
        Some(Login(username, _)) ->
          Model(
            ..model,
            login_popup: Some(Login(username: username, password: new_password)),
          )
        Some(SignUp(username, _)) ->
          Model(
            ..model,
            login_popup: Some(Login(username: username, password: new_password)),
          )
      },
      effect.none(),
    )

    ApiRetunedLoginAttempt(response) -> #(
      case response {
        Ok(attempt) ->
          case attempt, model.login_popup {
            Ok(success), Some(Loading) ->
              Model(
                ..model,
                local_user: Some(success.user),
                auth_token: Some(success.auth_token),
              )
            // TODO: Change this
            Ok(_), _ -> {
              io.debug("Got LoginAttemptResponse when not loading")
              model
            }
            Error(error), _ -> {
              io.debug(error)
              model
            }
          }
        Error(error) -> {
          io.print_error("Http error response from LoginAttemptResponse: ")
          io.debug(error)
          model
        }
      },
      effect.none(),
    )
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
            // NOTE: This is sort of for debugging
            Some(creator) ->
              creator.name <> " (" <> int.to_string(creator.id) <> ")"
            None -> "Anonymous"
          }),
        ]),
      ])
    })

  let login_signup_form = fn(submit_button_value, username, password) {
    html.form([event.on_submit(UserRequestedNewLoginPopUp(None))], [
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
        None -> [
          html.button(
            [
              event.on_click(UserRequestedNewLoginPopUp(
                // TODO: This shouldn't really be wrapped in a optional
                Some(Login(username: "", password: "")),
              )),
            ],
            [html.text("Login")],
          ),
          html.button(
            [
              event.on_click(
                UserRequestedNewLoginPopUp(
                  Some(SignUp(username: "", password: "")),
                ),
              ),
            ],
            [html.text("Sign Up")],
          ),
        ]
        Some(user) -> [html.text(user.name)]
      }),
    ]),
    html.main([], [
      case model.login_popup {
        None -> element.none()
        Some(popup) ->
          case popup {
            Login(username, password) ->
              login_signup_form("Login", username, password)
            SignUp(username, password) ->
              login_signup_form("Sign Up", username, password)
            // NOTE: Differentiate between different loading states?
            Loading -> html.text("WAITING FOR SERVER RESPONSE!")
          }
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
            attribute.value(model.current_todo_input_content),
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

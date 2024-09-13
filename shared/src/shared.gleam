import gleam/dynamic
import gleam/json
import gleam/option
import gleam/result

pub type LoginOrSignUp {
  Login
  SignUp
}

pub type User {
  User(id: Int, name: String)
}

pub type LoginAttempt {
  LoginAttempt(username: String, password: String)
}

pub type LoginAttemptResponseFailure {
  IncorrectPassword
  UserNotFound
}

pub type LoginAttemptResponseSuccess {
  LoginAttemptResponseSuccess(auth_token: String, user: User)
}

pub type LoginAttemptResponse =
  Result(LoginAttemptResponseSuccess, LoginAttemptResponseFailure)

pub fn decode_login_attempt_response(
  json: dynamic.Dynamic,
) -> Result(LoginAttemptResponse, dynamic.DecodeErrors) {
  let result_optional_error_string =
    json |> dynamic.optional_field("error", dynamic.string)

  result_optional_error_string
  |> result.try(fn(optional_error_string) {
    case optional_error_string {
      option.Some(error_string) ->
        case error_string {
          "incorrectPassword" -> Ok(Error(IncorrectPassword))
          "userNotFound" -> Ok(Error(UserNotFound))
          _ ->
            Error([
              dynamic.DecodeError(
                "incorrectPassword or userNotFound",
                error_string,
                [],
              ),
            ])
        }
      option.None -> {
        dynamic.field(
          "ok",
          dynamic.decode2(
            LoginAttemptResponseSuccess,
            dynamic.field("authToken", dynamic.string),
            dynamic.field(
              "user",
              dynamic.decode2(
                User,
                dynamic.field("id", dynamic.int),
                dynamic.field("name", dynamic.string),
              ),
            ),
          ),
        )(json)
        |> result.map(fn(success) { Ok(success) })
      }
    }
  })
}

pub fn decode_login_attempt(
  json: dynamic.Dynamic,
) -> Result(LoginAttempt, dynamic.DecodeErrors) {
  let decoder =
    dynamic.decode2(
      LoginAttempt,
      dynamic.field("username", dynamic.string),
      dynamic.field("password", dynamic.string),
    )

  decoder(json)
}

pub fn encode_login_attempt(attempt: LoginAttemptResponse) -> json.Json {
  case attempt {
    Ok(success) ->
      json.object([
        #(
          "ok",
          json.object([
            #("authToken", json.string(success.auth_token)),
            #(
              "user",
              json.object([
                #("id", json.int(success.user.id)),
                #("name", json.string(success.user.name)),
              ]),
            ),
          ]),
        ),
      ])
    Error(error) ->
      json.object([
        #(
          "error",
          case error {
            IncorrectPassword -> "incorrectPassword"
            UserNotFound -> "userNotFound"
          }
            |> json.string,
        ),
      ])
  }
}

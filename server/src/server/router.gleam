import gleam/json
import gleam/result
import shared
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  // io.debug(req)
  use json <- wisp.require_json(req)

  let result = {
    use person <- result.try(shared.decode_login_attempt(json))

    let response = case person.username, person.password {
      //TODO: Make database request
      "steve", "jobs" ->
        Ok(shared.LoginAttemptResponseSuccess(
          auth_token: "AUTH_TOKEN",
          user: shared.User(name: "steve", id: 1),
        ))
      "steve", _ -> Error(shared.IncorrectPassword)
      _, _ -> Error(shared.UserNotFound)
    }
    Ok(json.to_string_builder(shared.encode_login_attempt(response)))
  }

  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(_) -> wisp.unprocessable_entity()
  }
}

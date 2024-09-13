import gleam/dynamic
import gleam/io
import gleam/json
import gleam/pgo
import gleam/result
import gleam/string
import server/web
import shared
import wisp

// TODO: Remove all assertions and panics here

pub fn login(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  use json <- wisp.require_json(req)

  let result = {
    use login_information <- result.try(shared.decode_login_attempt(json))

    let sql =
      "
    SELECT 
      id, password
    FROM 
      users
    WHERE
      name = $1"

    let result_type = dynamic.tuple2(dynamic.int, dynamic.string)

    let assert Ok(db_response) =
      pgo.execute(
        sql,
        ctx.db,
        [pgo.text(login_information.username)],
        result_type,
      )

    let response = case db_response.rows {
      [] -> Error(shared.UserNotFound)
      [id_and_password] -> {
        // TODO: Hash and salted passwords
        case login_information.password == string.trim(id_and_password.1) {
          True ->
            Ok(shared.LoginAttemptResponseSuccess(
              auth_token: "AUTH_TOKEN",
              user: shared.User(name: "steve", id: 1),
            ))
          False -> Error(shared.IncorrectPassword)
        }
      }
      _ -> panic
    }
    Ok(json.to_string_builder(shared.encode_login_attempt(response)))
  }

  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(_) -> wisp.unprocessable_entity()
  }
}

pub fn signup(req: wisp.Request, ctx: web.Context) -> wisp.Response {
  todo
}

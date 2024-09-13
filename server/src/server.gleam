import envoy
import gleam/erlang/process
import gleam/pgo
import gleam/result
import mist
import server/router
import server/web
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)

  let assert Ok(db) = read_connection_uri()
  let context = web.Context(db)

  let handler = router.handle_request(_, context)

  let assert Ok(_) =
    wisp_mist.handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

fn read_connection_uri() -> Result(pgo.Connection, Nil) {
  use database_url <- result.try(envoy.get("DATABASE_URL"))
  use config <- result.try(pgo.url_config(database_url))
  Ok(pgo.connect(config))
}

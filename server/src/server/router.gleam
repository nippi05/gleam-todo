import server/web
import server/web/todos
import server/web/users
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["login"] -> users.login(req, ctx)
    ["signup"] -> users.signup(req, ctx)
    ["user", id, "todos"] -> todos.todos_of_creator(req, ctx, id)
    ["todo", id] -> todos.todo_of_id(req, ctx, id)
    _ -> wisp.not_found()
  }
}

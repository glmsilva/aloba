import gleam/io
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{None}
import gleam/result
import gleam/string
import gleam/list
import logging
import mist.{type Connection, type ResponseData}

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let not_found = 
    response.new(404)

  let assert Ok(_) =
  fn(req: Request(Connection)) -> Response(ResponseData) {
    // let client_info = mist.get_client_info(req.body)

    case request.path_segments(req) {
      [] -> {
          string.inspect(fetch_client_info(mist.get_client_info(req.body)))
          string.inspect(resolve_request_info(req))

          response.new(200)
        |> response.set_body(mist.Bytes(bytes_tree.new()))
        }

      _ -> not_found
      |> response.set_body(mist.Bytes(bytes_tree.new()))
    }
  }
  |> mist.new
  |> mist.bind("localhost")
  |> mist.port(8080)
  |> mist.start

  process.sleep_forever()
}

fn fetch_client_info(val: Result(mist.ConnectionInfo, Nil)) {
  case val {
    Ok(info) -> io.println("Received a request from: " <> resolve_ip_address(info.ip_address))
    Error(_) -> Nil
  }
}

fn resolve_ip_address(val: mist.IpAddress) -> String {
  mist.ip_address_to_string(val)
}

fn resolve_request_info(val: Request(Connection)) {
  let headers = val.headers

  io.println(http.method_to_string(val.method) <> " " <> http.scheme_to_string(val.scheme))
  list.each(headers, fn(pair) {
    case pair {
      #(key, value) ->
        case key {
          "host" -> io.println("Host: " <> value)
          "user-agent" -> io.println("User-Agent: " <> value)
          "accept" -> io.println("Accept: " <> value)
          _ -> Nil
        }
      _ -> Nil
    }
  })
}

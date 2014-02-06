defmodule ExplexWeb.Router do
  use Plug.Router
  import Plug.Connection

  def call(conn, _opts) do
    if IEx.started? do
      try do
        dispatch(conn.method, conn.path_info, conn)
      catch
        kind, error ->
          print_error(kind, error, System.stacktrace)
          if impl = Plug.Exception.impl_for(error) do
            { :halt, send_resp(conn, impl.status(error), "") }
          else
            { :halt, send_resp(conn, 500, "") }
          end
      end
    else
      dispatch(conn.method, conn.path_info, conn)
    end
  end

  defp print_error(:error, exception, stacktrace) do
    IO.inspect ""
    exception = Exception.normalize(exception)
    IO.puts IO.ANSI.escape_fragment("\n%{red}** (#{inspect exception.__record__(:name)}) #{exception.message}", true)
    IO.puts IEx.Evaluator.format_stacktrace(stacktrace)
  end

  defp print_error(kind, reason, stacktrace) do
    IO.puts IO.ANSI.escape_fragment("\n%{red}** (#{kind}) #{inspect(reason)}", true)
    IO.puts IEx.Evaluator.format_stacktrace(stacktrace)
  end

  match "/api/beta/*glob" do
    conn = conn.path_info(glob)
    ExplexWeb.Router.API.call(conn, [])
  end

  match _ do
    { :halt, send_resp(conn, 404, "") }
  end
end

defmodule ExplexWeb.Router.API do
  use Plug.Router
  import Plug.Connection
  alias ExplexWeb.User
  alias ExplexWeb.Package

  def call(conn, _opts) do
    case Plug.Parsers.call(conn, parsers: [ExplexWeb.Util.JsonDecoder]) do
      { :ok, conn } ->
        dispatch(conn.method, conn.path_info, conn)
      error ->
        error
    end
  end

  post "user" do
    case User.create(conn.params["username"], conn.params["email"], conn.params["password"]) do
      { :ok, _ } ->
        { :ok, send_resp(conn, 201, "") }
      { :error, errors } ->
        { :halt, send_validation_failed(conn, errors) }
    end
  end

  match _ do
    { :ok, send_resp(conn, 404, "") }
  defp send_validation_failed(conn, errors) do
    body = [message: "Validation failed", errors: errors]
    send_resp(conn, 422, JSON.encode!(body))
  end
end

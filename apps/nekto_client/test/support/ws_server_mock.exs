defmodule Support.WSServerMock do
  use GenServer

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def start(server, port) do
    GenServer.cast(server, {:start, port})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_cast({:start, port}, state) do
    socket = port |> Socket.Web.listen! |> Socket.Web.accept!
    Socket.Web.accept! socket
    send_json!(socket, %{notice: "success_connected"})
    listen(socket)
    {:noreply, state}
  end

  defp send_json!(socket, json) do
    Socket.Web.send!(socket, {:text, Poison.encode!(json)})
  end

  defp listen(socket) do
    case Socket.Web.recv!(socket) do
      {:text, data} ->
        socket |> handle_message(Poison.decode!(data))
      {:ping, _} ->
        Socket.Web.send!(socket, {:pong, ""})
    end
    listen(socket)
  end

  defp handle_message(socket, %{"action" => "COUNT_ONLINE_USERS"}) do
    socket |> send_json!(%{notice: "count_online_users", message: %{count: 1000}})
    socket |> send_json!(%{notice: "count_insearch_users", message: %{count: 100}})
  end

  defp handle_message(socket, %{"action" => "AUTH"}) do
    socket |> send_json!(%{notice: "success_auth", message: %{user: %{id: 12345}, open_dialogs: []}})
  end
end

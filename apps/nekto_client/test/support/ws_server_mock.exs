defmodule Support.WSServerMock do
  use GenServer
  alias Socket.Web

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
    socket = port |> Web.listen! |> Web.accept!
    Web.accept! socket
    send_json!(socket, %{notice: "success_connected"})
    listen(socket)
    {:noreply, state}
  end

  defp send_json!(socket, json) do
    Web.send!(socket, {:text, Poison.encode!(json)})
  end

  defp listen(socket) do
    case Web.recv!(socket) do
      {:text, data} ->
        socket |> handle_message(Poison.decode!(data))
      {:ping, _} ->
        socket |> Web.send!({:pong, ""})
      {:pong, _} ->
        socket |> send_json!(%{notice: "pong"})
    end
    listen(socket)
  end

  defp handle_message(socket, %{"action" => "COUNT_ONLINE_USERS"}) do
    socket
    |> send_json!(%{notice: "count_online_users", message: %{count: 1000}})
    socket
    |> send_json!(%{notice: "count_insearch_users", message: %{count: 100}})
  end

  defp handle_message(socket, %{"action" => "AUTH",
                                "user_token" => "user_token"}) do
    socket
    |> send_json!(%{notice: "success_auth",
                    message: %{user: %{id: 12_345}, open_dialogs: []}})
  end

  defp handle_message(socket, %{"action" => "AUTH"}) do
    socket
    |> send_json!(%{notice: "success_auth",
                    message: %{user: %{id: 54_321}, open_dialogs: []}})
  end

  defp handle_message(socket, %{"action" => "SEARCH_COMPANY",
                                "my_sex" => "M", "wish_sex" => "F",
                                "my_age_from" => "18", "my_age_to" => "21",
                                "wish_age" => ["0t17", "18t21"]}) do
    socket
    |> send_json!(%{notice: "open_dialog",
                    message: %{id: 10, uids: [12_345, 67_890]}})
  end

  defp handle_message(socket, %{"action" => "SEARCH_COMPANY"}) do
    socket
    |> send_json!(%{notice: "open_dialog",
                    message: %{id: 100, uids: [54_321, 98_765]}})
  end

  defp handle_message(socket, %{"action" => "TYPING_A_MESSAGE",
                                 "dialog_id" => 100, "typing" => true}) do
    socket
    |> send_json!(%{notice: "typing_a_message"})
  end

  defp handle_message(socket, %{"action" => "CHAT_MESSAGE",
                                "dialog_id" => 100, "text" => "test message 1",
                                "request_id" => "54321_1"}) do
    socket
    |> send_json!(%{notice: "success_send_message", request_id: "54321_1",
                    message: %{"message_id" => 11_111}})
  end

  defp handle_message(socket, %{"action" => "CHAT_MESSAGE",
                                "dialog_id" => 100, "text" => "test message 2",
                                "request_id" => "54321_2"}) do
    socket
    |> send_json!(%{notice: "success_send_message", request_id: "54321_2",
                    message: %{"message_id" => 22_222}})
  end

  defp handle_message(socket, %{"action" => "CHAT_MESSAGE_READ",
                                "message_ids" => [1,2,3],
                                "dialog_id" => 100}) do
    socket
    |> send_json!(%{notice: "chat_message_read"})
  end

  defp handle_message(socket, %{"action" => "OUT_SEARCH_COMPANY"}) do
    socket
    |> send_json!(%{notice: "out_search_company"})
  end

  defp handle_message(socket, %{"action" => "LEAVE_DIALOG",
                                "dialog_id" => 100}) do
    socket
    |> send_json!(%{notice: "success_leave", message: %{dialog_id: 100}})
  end

  ## Handlers for testing goals

  defp handle_message(socket, %{"test" => "ping"}) do
    socket
    |> Web.send!({:ping, ""})
  end

  defp handle_message(socket, %{"test" => "chat_new_message"}) do
    socket
    |> send_json!(%{
      notice: "chat_new_message",
      message: %{dialog_id: 100, user: %{id: 98_765, name: ""},
                 text: "test message", message_id: 33_333}
    })
  end
end

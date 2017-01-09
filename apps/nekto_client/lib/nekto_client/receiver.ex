defmodule NektoClient.Receiver do
  use GenServer

  ## Client API

  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  def start_listening(receiver) do
    GenServer.cast(receiver, {:listening})
  end

  def add_handler(receiver, handler, args) do
    GenServer.call(receiver, {:add_handler, handler, args})
  end

  def remove_handler(receiver, handler, args) do
    GenServer.call(receiver, {:remove_handler, handler, args})
  end

  ## Server Callbacks

  def init({:ok, socket}) do
    {:ok, ge_pid} = GenEvent.start_link([])
    {:ok, %{socket: socket, ge_pid: ge_pid}}
  end

  def handle_cast({:listening}, %{socket: socket, ge_pid: ge_pid}) do
    listen(socket, ge_pid)
  end

  def handle_call({:add_handler, handler, args}, _from, ge_pid) do
    {:reply, GenEvent.add_handler(ge_pid, handler, args)}
  end

  def handle_call({:remove_handler, handler, args}, _from, ge_pid) do
    {:reply, GenEvent.remove_handler(ge_pid, handler, args)}
  end

  defp listen(socket, ge_pid) do
    case NektoClient.WSClient.recv!(socket) do
      {:json, response}
        -> GenEvent.notify(ge_pid, handle_response(response))
      {:ping, _}
        -> Socket.Web.send!(socket, {:pong, ""})
      _ -> :error
    end
    listen(socket, ge_pid)
  end

  defp handle_response(%{"notice" => "success_auth", "message" => message}) do
    %{"user" => %{"id" => id}} = message
    {"success_auth", NektoClient.Model.User.new(id)}
  end

  defp handle_response(%{"notice" => "open_dialog", "message" => message}) do
    %{"id" => id, "uids" => uids} = message
    {"open_dialog", NektoClient.Model.Dialog.new(id, uids)}
  end

  defp handle_response(%{"notice" => "chat_new_message", "message" => message}) do
    %{"message_id" => id, "dialog_id" => dialog_id,
      "user" => %{"id" => uid}, "text" => text} = message
      message = NektoClient.Model.Message.new(id, dialog_id, uid, text)
    {"chat_new_message", message}
  end

  defp handle_response(%{"notice" => notice, "message" => message}) do
    {notice, %{message: message}}
  end

  defp handle_response(%{"notice" => notice}) do
    {notice, %{}}
  end
end

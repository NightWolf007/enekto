defmodule NektoClient.Receiver do
  use GenServer

  ## Client API

  @doc """
  Starts receiver
  """
  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  @doc """
  Starts listenning loop. After the loop starts you can't call Client API
  """
  def start_listening(receiver) do
    GenServer.cast(receiver, {:listening})
  end

  @doc """
  Adds handler to GenEvent
  """
  def add_handler(receiver, handler, args) do
    GenServer.call(receiver, {:add_handler, handler, args})
  end

  @doc """
  Remove handler from GenEvent
  """
  def remove_handler(receiver, handler, args) do
    GenServer.call(receiver, {:remove_handler, handler, args})
  end

  @doc """
  Returns GenEvent pid
  """
  def gen_event(receiver) do
    GenServer.call(receiver, {:gen_event})
  end

  ## Server Callbacks

  def init({:ok, socket}) do
    {:ok, ge_pid} = GenEvent.start_link([])
    {:ok, %{socket: socket, ge_pid: ge_pid}}
  end

  def handle_cast({:listening}, %{socket: socket, ge_pid: ge_pid}) do
    listen(socket, ge_pid)
  end

  def handle_call({:add_handler, handler, args}, _from, state) do
    state
    |> Map.get(:ge_pid)
    |> GenEvent.add_handler(handler, args)
    |> reply_response(state)
  end

  def handle_call({:remove_handler, handler, args}, _from, state) do
    state
    |> Map.get(:ge_pid)
    |> GenEvent.remove_handler(handler, args)
    |> reply_response(state)
  end

  def handle_call({:gen_event}, _from, state) do
    {:reply, Map.get(state, :ge_pid), state}
  end

  def reply_response(response, state) do
    {:reply, response, state}
  end

  defp listen(socket, ge_pid) do
    case NektoClient.WSClient.recv!(socket) do
      {:json, response} ->
        GenEvent.notify(ge_pid, handle_response(response))
      {:ping, _} ->
        Socket.Web.send!(socket, {:pong, ""})
      _ ->
        :error
    end
    listen(socket, ge_pid)
  end

  defp handle_response(%{"notice" => "success_auth", "message" => message}) do
    %{"user" => %{"id" => id}} = message
    {:success_auth, NektoClient.Model.User.new(id)}
  end

  defp handle_response(%{"notice" => "open_dialog", "message" => message}) do
    %{"id" => id, "uids" => uids} = message
    {:open_dialog, NektoClient.Model.Dialog.new(id, uids)}
  end

  defp handle_response(%{"notice" => "chat_new_message", "message" => message}) do
    %{"message_id" => id, "dialog_id" => dialog_id,
      "user" => %{"id" => uid}, "text" => text} = message
    msg = NektoClient.Model.Message.new(id, dialog_id, uid, text)
    {:chat_new_message, msg}
  end

  defp handle_response(%{"notice" => notice, "message" => message}) do
    {String.to_atom(notice), message}
  end

  defp handle_response(%{"notice" => notice}) do
    {String.to_atom(notice), %{}}
  end
end

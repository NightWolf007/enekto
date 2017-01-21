defmodule NektoClient.Sender do
  @moduledoc """
  GenServer for sending messages to Nekto.me websocket
  """
  use GenServer
  alias NektoClient.WSClient
  alias NektoClient.Model.Search

  ## Client API

  @doc """
  Starts sender
  """
  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  @doc """
  Saves user in state
  """
  def set_user(sender, user) do
    GenServer.call(sender, {:set_user, user})
  end

  @doc """
  Saves dialog in state
  """
  def set_dialog(sender, dialog) do
    GenServer.call(sender, {:set_dialog, dialog})
  end

  @doc """
  Returns socket

  ## Examples

      iex> {:ok, sender} = NektoClient.Sender.start_link("socket")
      iex> NektoClient.Sender.get_socket(sender)
      "socket"
  """
  def get_socket(sender) do
    GenServer.call(sender, {:get_socket})
  end

  @doc """
  Sends COUNT_ONLINE_USERS action to the server
  """
  def count_online_users(sender) do
    GenServer.call(sender, {:count_online_users})
  end

  @doc """
  Sends AUTH action with user_token to the server
  """
  def authenticate(sender, user_token) do
    GenServer.call(sender, {:authenticate, user_token})
  end

  @doc """
  Sends SEARCH_COMPANY action with serach params to the server
  """
  def search(sender, search_params) do
    GenServer.call(sender, {:search, search_params})
  end

  @doc """
  Sends TYPING_A_MESSAGE action with typing status to the server
  status - true or false
  Dialog must be set
  """
  def typing(sender, status) do
    GenServer.call(sender, {:typing, status})
  end

  @doc """
  Sends CHAT_MESSAGE action with message to the server
  User must be set
  Dialog must be set
  """
  def send(sender, message) do
    GenServer.call(sender, {:send, message})
  end

  @doc """
  Sends CHAT_MESSAGE_READ action with list of messages to the server
  Dialog must be set
  """
  def read_messages(sender, messages) do
    GenServer.call(sender, {:read_messages, messages})
  end

  @doc """
  Sends LEAVE_DIALOG action to the server
  Dialog must be set
  """
  def leave_dialog(sender) do
    GenServer.call(sender, {:leave_dialog})
  end

  @doc """
  Sends OUT_SEARCH_COMPANY action to the server
  """
  def leave_search(sender) do
    GenServer.call(sender, {:leave_search})
  end

  ## Server Callbacks

  def init({:ok, socket}) do
    {:ok, %{socket: socket}}
  end

  def handle_call({:set_user, user}, _from, state) do
    {:reply, user, Map.merge(state, %{user: user, request_counter: 1})}
  end

  def handle_call({:set_dialog, dialog}, _from, state) do
    {:reply, dialog, Map.merge(state, %{dialog: dialog, request_counter: 1})}
  end

  def handle_call({:get_socket}, _from, state) do
    {:reply, Map.get(state, :socket), state}
  end

  def handle_call({:count_online_users}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.count_online_users!()
    |> reply_response(state)
  end

  def handle_call({:authenticate, user_token}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.auth!(user_token)
    |> reply_response(state)
  end

  def handle_call({:search, search_params}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.search_company!(Search.format(search_params))
    |> reply_response(state)
  end

  def handle_call({:typing, status}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.typing_message!(Map.get(state, :dialog).id, status)
    |> reply_response(state)
  end

  def handle_call({:send, message}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.chat_message!(Map.get(state, :dialog).id,
                              request_id(state), message)
    |> reply_response(Map.put(state, :request_counter,
                              Map.get(state, :request_counter) + 1))
  end

  def handle_call({:read_messages, messages}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.chat_message_read!(Map.get(state, :dialog).id,
                                   Enum.map(messages, &(&1.id)))
    |> reply_response(state)
  end

  def handle_call({:leave_dialog}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.leave_dialog!(Map.get(state, :dialog).id)
    |> reply_response(Map.put(state, :dialog, nil))
  end

  def handle_call({:leave_search}, _from, state) do
    state
    |> Map.get(:socket)
    |> WSClient.out_search_company!()
    |> reply_response(state)
  end

  defp reply_response(response, state) do
    {:reply, response, state}
  end

  defp request_id(state) do
    "#{Map.get(state, :user).id}_#{Map.get(state, :request_counter)}"
  end
end

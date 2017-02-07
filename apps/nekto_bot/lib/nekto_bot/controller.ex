defmodule NektoBot.Controller do
  @moduledoc """
  Controller that handles commands
  """

  use GenServer
  alias Nekto.Supervisor
  alias NektoClient.Receiver
  alias NektoBot.Forwarder

  ## Client API

  @doc """
  Starts controller
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Handles command
  """
  def exec(controller, command, message) do
    GenServer.call(controller, {:exec, command, message})
  end

  @doc """
  Handles unknown command
  """
  def unknown_command(controller, message) do
    GenServer.call(controller, {:unknown_command, message})
  end

  ## Server Callbacks

  def init(:ok) do
    chats = :ets.new(:chats, [:set, :protected, read_concurrency: true])
    {:ok, {chats}}
  end

  def handle_call({:exec, {:connect}, message}, _from, {chats}) do
    {:ok, supervisor} = Nekto.Supervisor.start_link("chat.nekto.me",
                                                    path: "/websocket")

    supervisor
    |> Supervisor.client_a_receiver
    |> Receiver.add_handler(Forwarder,
                            %{chat_id: chat_id(message), client: "A"})

    supervisor
    |> Supervisor.client_b_receiver
    |> Receiver.add_handler(Forwarder,
                            %{chat_id: chat_id(message), client: "B"})

    supervisor
    |> Supervisor.start_listening

    supervisor
    |> Supervisor.authenticate("nekto.me")

    :ets.insert(chats, {chat_id(message), supervisor})
    {:reply, :ok, {chats}}
  end

  def handle_call({:exec, {:reconnect}, message}, from, {chats}) do
    chat_id = chat_id(message)
    case :ets.lookup(chats, chat_id) do
      [{^chat_id, supervisor}] ->
        Supervisor.stop(supervisor)
      [] ->
        :error
    end

    handle_call({:exec, {:connect}, message}, from, {chats})
  end

  def handle_call({:exec, command, message}, _from, state) do
    handle_command(command, message)
    {:reply, :ok, state}
  end

  def handle_call({:unknown_command, message}, _from, state) do
    message
    |> chat_id
    |> Nadia.send_message("Error! Unknown command")
    {:reply, :ok, state}
  end

  defp handle_command({:set, client, params}, message) do
    message
    |> chat_id
    |> Nadia.send_message(
         "Params for client #{client} setted as #{inspect params}"
       )
  end

  defp handle_command({:search, client}, message) do
    message
    |> chat_id
    |> Nadia.send_message("Searching for client #{client}...")
  end

  defp handle_command({:search}, message) do
    handle_command({:search, "A"}, message)
    handle_command({:search, "B"}, message)
  end

  defp handle_command({:kick, client}, message) do
    message
    |> chat_id
    |> Nadia.send_message("Client #{client} kicked")
  end

  defp handle_command({:mute, client}, message) do
    message
    |> chat_id
    |> Nadia.send_message("Client #{client} muted")
  end

  defp handle_command({:send, client, text}, message) do
    message
    |> chat_id
    |> Nadia.send_message("YOU => #{client} -> #{text}")
  end

  defp chat_id(message) do
    message
    |> Map.get(:chat)
    |> Map.get(:id)
  end
end

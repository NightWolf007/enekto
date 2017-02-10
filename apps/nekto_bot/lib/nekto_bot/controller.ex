defmodule NektoBot.Controller do
  @moduledoc """
  Controller that handles commands
  """

  use GenServer
  alias Nekto.Supervisor
  alias NektoClient.Sender
  alias NektoClient.Receiver
  alias NektoClient.Model.Search
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
    pids = :ets.new(:pids, [:set, :protected, read_concurrency: true])
    settings = :ets.new(:settings, [:set, :protected, read_concurrency: true])
    {:ok, {pids, settings}}
  end

  def handle_call({:exec, {:connect}, message}, _from, {pids, _} = state) do
    {:ok, supervisor} = Nekto.Supervisor.start_link("chat.nekto.me",
                                                    path: "/websocket")

    supervisor
    |> Supervisor.client_a_receiver
    |> Receiver.add_handler(
         Forwarder,
         %{chat_id: chat_id(message), client: :a,
           forwarding_controller: Supervisor.forwarding_controller(supervisor)}
       )

    supervisor
    |> Supervisor.client_b_receiver
    |> Receiver.add_handler(
         Forwarder,
         %{chat_id: chat_id(message), client: :b,
           forwarding_controller: Supervisor.forwarding_controller(supervisor)}
       )

    supervisor
    |> Supervisor.start_listening

    supervisor
    |> Supervisor.authenticate("nekto.me")

    chat_id = chat_id(message)
    :ets.insert(pids, {chat_id, supervisor})

    Nadia.send_message(chat_id, "Successfully connected!")

    {:reply, :ok, state}
  end

  def handle_call({:exec, {:reconnect}, message}, from, {pids, settings}) do
    chat_id = chat_id(message)
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        Supervisor.stop(supervisor)
        Nadia.send_message(chat_id, "Connection closed.")
      [] ->
        :error
    end

    handle_call({:exec, {:connect}, message}, from, {pids, settings})
  end

  def handle_call({:exec, {:set, client, params}, message}, _from, {pids, settings}) do
    chat_id = chat_id(message)
    value = case :ets.lookup(settings, chat_id) do
      [{^chat_id, clients_params}] ->
        Map.merge(clients_params, %{client => params})
      [] ->
        %{client => params}
    end
    :ets.insert(settings, {chat_id, value})
    Nadia.send_message(
      chat_id,
      "Client #{client} setted as #{inspect(params)}."
    )
    {:reply, :ok, {pids, settings}}
  end

  def handle_call({:exec, {:search}, message}, _from, {pids, settings} = state) do
    chat_id = chat_id(message)
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        case :ets.lookup(settings, chat_id) do
          [{^chat_id, clients_params}] ->
            supervisor
            |> Supervisor.client_a_sender
            |> Sender.search(Search.from_hash(Map.get(clients_params, "A")))

            supervisor
            |> Supervisor.client_b_sender
            |> Sender.search(Search.from_hash(Map.get(clients_params, "B")))

            Nadia.send_message(chat_id, "Searching clients...")
            {:reply, :ok, state}
          [] ->
            Nadia.send_message(
              chat_id,
              "Error! Clients haven't setted. " <>
              "Please, set both clients and try again."
            )
            {:reply, :error, state}
        end
      [] ->
        Nadia.send_message(
          chat_id,
          "Error! Clients haven't connected. Please, connect and try again."
        )
        {:reply, :error, state}
    end
  end

  def handle_call({:unknown_command, message}, _from, state) do
    message
    |> chat_id
    |> Nadia.send_message("Error! Unknown command")
    {:reply, :ok, state}
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

defmodule NektoBot.Controller do
  @moduledoc """
  Controller that handles commands
  """

  use GenServer
  alias Nekto.Supervisor
  alias Nekto.ForwardingController
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
         %{chat_id: chat_id(message), client: :a}
       )

    supervisor
    |> Supervisor.client_b_receiver
    |> Receiver.add_handler(
         Forwarder,
         %{chat_id: chat_id(message), client: :b}
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

  def handle_call({:exec, {:search, client}, message}, _from, {pids, settings} = state) do
    chat_id = chat_id(message)
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        case :ets.lookup(settings, chat_id) do
          [{^chat_id, %{^client => params}}] ->
            if(client == "A") do
              supervisor
              |> Supervisor.client_a_sender
              |> Sender.search(Search.from_hash(params))
            else
              supervisor
              |> Supervisor.client_b_sender
              |> Sender.search(Search.from_hash(params))
            end

            Nadia.send_message(chat_id, "Searching client #{client}...")
            {:reply, :ok, state}
          [] ->
            Nadia.send_message(
              chat_id,
              "Error! Client #{client} haven't setted. " <>
              "Please, set both clients and try again."
            )
            {:reply, :error, state}
        end
      [] ->
        Nadia.send_message(
          chat_id,
          "Error! Client #{client} haven't connected. " <>
          "Please, connect and try again."
        )
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:search}, message}, from, state) do
    handle_call({:exec, {:search, "A"}, message}, from, state)
    handle_call({:exec, {:search, "B"}, message}, from, state)
  end

  def handle_call({:exec, {:send, client, text}, message}, _from, {pids, _} = state) do
    chat_id = chat_id(message)
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        client_name = client |> String.downcase |> String.to_atom
        if supervisor |> Supervisor.forwarding_controller
                      |> ForwardingController.connected?(client_name) do
          if(client == "A") do
            supervisor
            |> Supervisor.client_a_sender
            |> Sender.send(text)
          else
            supervisor
            |> Supervisor.client_b_sender
            |> Sender.send(text)
          end

          Nadia.send_message(chat_id, "YOU => #{client} -> #{text}")
          {:reply, :ok, state}
        else
          Nadia.send_message(
            chat_id,
            "Error! Client #{client} haven't found yet. " <>
            "Please, search it or wait."
          )
          {:reply, :error, state}
        end
      [] ->
        Nadia.send_message(
          chat_id,
          "Error! Client #{client} haven't connected. " <>
          "Please, connect and try again."
        )
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:mute, client}, message}, _from, {pids, _} = state) do
    chat_id = chat_id(message)
    client_name = client |> String.downcase |> String.to_atom
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        supervisor
        |> Supervisor.forwarding_controller
        |> ForwardingController.mute(client_name)

        Nadia.send_message(chat_id, "Client #{client} muted.")
        {:reply, :ok, state}
      [] ->
        Nadia.send_message(
          chat_id,
          "Error! Client #{client} haven't connected. " <>
          "Please, connect and try again."
        )
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:unmute, client}, message}, _from, {pids, _} = state) do
    chat_id = chat_id(message)
    client_name = client |> String.downcase |> String.to_atom
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        supervisor
        |> Supervisor.forwarding_controller
        |> ForwardingController.unmute(client_name)

        Nadia.send_message(chat_id, "Client #{client} unmuted.")
        {:reply, :ok, state}
      [] ->
        Nadia.send_message(
          chat_id,
          "Error! Client #{client} haven't connected. " <>
          "Please, connect and try again."
        )
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:kick, client}, message}, _from, {pids, _} = state) do
    chat_id = chat_id(message)
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, supervisor}] ->
        if(client == "A") do
          supervisor
          |> Supervisor.client_a_sender
          |> Sender.leave_dialog
        else
          supervisor
          |> Supervisor.client_b_sender
          |> Sender.leave_dialog
        end

        Nadia.send_message(chat_id, "Client #{client} kicked.")
        {:reply, :ok, state}
      [] ->
        Nadia.send_message(
          chat_id,
          "Error! Client #{client} haven't connected. " <>
          "Please, connect and try again."
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

  defp chat_id(message) do
    message
    |> Map.get(:chat)
    |> Map.get(:id)
  end
end

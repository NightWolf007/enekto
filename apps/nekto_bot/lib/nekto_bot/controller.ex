defmodule NektoBot.Controller do
  @moduledoc """
  Controller that handles commands
  """

  use GenServer
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
    GenServer.call(controller, {:exec, command, chat_id(message), message})
  end

  @doc """
  Handles setup action
  """
  def setup(controller, input, client, fsm_state, message) do
    case fsm_state do
      :command_input ->
        GenServer.call(controller, {:setup, client, chat_id(message)})
      :my_sex_input ->
        GenServer.call(controller, {:setup, {"my_sex", input, client},
                                    chat_id(message)})
      :wish_sex_input ->
        GenServer.call(controller, {:setup, {"wish_sex", input, client},
                                             chat_id(message)})
      :my_age_input ->
        GenServer.call(controller, {:setup, {"my_age_from", elem(input, 0),
                                             client}, chat_id(message)})
        GenServer.call(controller, {:setup, {"my_age_to", elem(input, 1),
                                             client}, chat_id(message)})
      :wish_age_input ->
        GenServer.call(controller, {:setup, {"wish_age", input, client},
                                    chat_id(message)})
    end
  end

  @doc """
  Handles unknown command
  """
  def unknown_command(controller, message) do
    GenServer.call(controller, {:unknown_command, chat_id(message), message})
  end

  @doc """
  Returns settings for client
  """
  def settings(controller, chat_id, client) do
    GenServer.call(controller, {:settings, chat_id, client})
  end

  ## Server Callbacks

  def init(:ok) do
    pids = :ets.new(:pids, [:set, :private])
    settings = :ets.new(:settings, [:set, :private])
    {:ok, {pids, settings}}
  end

  def handle_call({:exec, {:connect}, chat_id, _}, _from, {pids, _} = state) do
    {:ok, nekto} = Nekto.start
    nekto
    |> Nekto.add_handler(:a, Forwarder, %{chat_id: chat_id, client: :a})
    nekto
    |> Nekto.add_handler(:b, Forwarder, %{chat_id: chat_id, client: :b})
    Nekto.start_listening(nekto)
    Nekto.authenticate(nekto)

    :ets.insert(pids, {chat_id, nekto})

    Nadia.send_message(chat_id, "Successfully connected!")

    {:reply, :ok, state}
  end

  def handle_call({:exec, {:reconnect}, chat_id, message}, from,
                  {pids, _} = state) do
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, nekto}] ->
        Nekto.stop(nekto)
        Nadia.send_message(chat_id, "Connection closed.")
      [] ->
        :not_found
    end
    handle_call({:exec, {:connect}, chat_id, message}, from, state)
    {:reply, :ok, state}
  end

  def handle_call({:exec, {:search, client}, chat_id, _}, _from,
                  {pids, settings} = state) do
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, nekto}] ->
        case :ets.lookup(settings, chat_id) do
          [{^chat_id, %{^client => params}}] ->
            Nekto.search(nekto, client, params)
            Nadia.send_message(chat_id,
                               "Searching client #{client_name(client)}...")
            {:reply, :ok, state}
          [] ->
            client_not_setted(chat_id, client)
            {:reply, :error, state}
        end
      [] ->
        client_not_connected(chat_id, client)
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:search}, chat_id, message}, from, state) do
    handle_call({:exec, {:search, :a}, chat_id, message}, from, state)
    handle_call({:exec, {:search, :b}, chat_id, message}, from, state)
  end

  def handle_call({:exec, {:send, client, text}, chat_id, _}, _from,
                  {pids, _} = state) do
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, nekto}] ->
        case Nekto.connected?(nekto, client) do
          {:ok, true} ->
            Nekto.send(nekto, client, text)
            Nadia.send_message(chat_id,
                               "YOU => #{client_name(client)} -> #{text}")
            {:reply, :ok, state}
          {:ok, false} ->
            client_not_found(chat_id, client)
            {:reply, :error, state}
        end
      [] ->
        client_not_connected(chat_id, client)
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:mute, client}, chat_id, _}, _from,
                  {pids, _} = state) do
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, nekto}] ->
        Nekto.mute(nekto, client)
        Nadia.send_message(chat_id, "Client #{client_name(client)} muted.")
        {:reply, :ok, state}
      [] ->
        client_not_connected(chat_id, client)
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:unmute, client}, chat_id, _}, _from,
                  {pids, _} = state) do
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, nekto}] ->
        Nekto.unmute(nekto, client)
        Nadia.send_message(chat_id, "Client #{client_name(client)} unmuted.")
        {:reply, :ok, state}
      [] ->
        client_not_connected(chat_id, client)
        {:reply, :error, state}
    end
  end

  def handle_call({:exec, {:kick, client}, chat_id, _}, _from,
                  {pids, _} = state) do
    case :ets.lookup(pids, chat_id) do
      [{^chat_id, nekto}] ->
        Nekto.kick(nekto, client)
        Nadia.send_message(chat_id, "Client #{client_name(client)} kicked.")
        {:reply, :ok, state}
      [] ->
        client_not_connected(chat_id, client)
        {:reply, :error, state}
    end
  end


  def handle_call({:setup, {param, input, client}, chat_id}, _from,
                  {_, settings} = state) do
    case :ets.lookup(settings, chat_id) do
      [{^chat_id, chat_settings}] ->
        client_settings = chat_settings
                          |> Map.get(client)
                          |> Map.put(param, input)
        :ets.insert(settings,
                    {chat_id, Map.put(chat_settings, client, client_settings)})
        {:reply, client_settings, state}
      [] ->
        {:reply, :error, state}
    end
  end

  def handle_call({:setup, client, chat_id}, _from, {_, settings} = state) do
    case :ets.lookup(settings, chat_id) do
      [{^chat_id, chat_settings}] ->
        {:reply, Map.get(chat_settings, client), state}
      [] ->
        chat_settings = %{a: %{}, b: %{}}
        :ets.insert(settings, {chat_id, chat_settings})
        {:reply, Map.get(chat_settings, client), state}
    end
  end


  def handle_call({:unknown_command, chat_id, _}, _from, state) do
    Nadia.send_message(chat_id, "Error! Unknown command")
    {:reply, :ok, state}
  end


  def handle_call({:settings, chat_id, client}, _from, {_, settings} = state) do
    case :ets.lookup(settings, chat_id) do
      [{^chat_id, chat_settings}] ->
        {:reply, Map.get(chat_settings, client), state}
      [] ->
        {:reply, %{}, state}
    end
  end


  defp client_not_connected(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Error! Client #{client_name(client)} haven't connected. " <>
      "Please, connect and try again."
    )
  end

  defp client_not_setted(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Error! Client #{client_name(client)} haven't setted. " <>
      "Please, set client and try again."
    )
  end

  defp client_not_found(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Error! Client #{client_name(client)} haven't found yet. " <>
      "Please, search it or wait."
    )
  end

  defp client_name(client) do
    client
    |> Atom.to_string
    |> String.upcase
  end

  defp chat_id(message) do
    message
    |> Map.get(:chat)
    |> Map.get(:id)
  end
end

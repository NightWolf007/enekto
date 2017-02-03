defmodule NektoBot.Controller do
  @moduledoc """
  Controller that handles commands
  """

  use GenServer

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
  """
  def new_message(controller, message, client) do
    GenServer.call(controller, {:new_message, message, client})
  end

  @doc """
  Handles unknown command
  """
  def unknown_command(controller, message) do
    GenServer.call(controller, {:unknown_command, message})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
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

  def handle_call({:new_message, message, client}, _from, state) do
    Nadia.send_message("#{client} -> #{message}")
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

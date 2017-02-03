defmodule NektoBot.Receiver do
  @moduledoc """
  GenServer for receiving messages from Telegram
  """

  use GenServer

  ## Client API

  @doc """
  Starts receiver
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
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

  def init(:ok) do
    {:ok, ge_pid} = GenEvent.start_link([])
    {:ok, %{ge_pid: ge_pid}}
  end

  def handle_cast({:listening}, %{ge_pid: ge_pid}) do
    listen(ge_pid, 0)
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

  defp listen(ge_pid, offset) do
    offset = case Nadia.get_updates(offset: offset,
                                    allowed_updates: ["message"]) do
      {:ok, []} ->
        offset
      {:ok, updates} ->
        handle_updates(ge_pid, updates)
        updates |> List.last |> Map.get(:update_id) |> Kernel.+(1)
      {:error, _} ->
        IO.puts "Error! Error happend while getting Telegram updates"
        offset
    end
    listen(ge_pid, offset)
  end

  defp handle_updates(ge_pid, updates) do
    Enum.each(updates, fn(update) -> handle_update(ge_pid, update) end)
  end

  defp handle_update(ge_pid, %{message: message}) when not is_nil(message) do
    GenEvent.notify(ge_pid, {:message, message})
  end

  defp handle_update(_ge_pid, _) do
  end
end

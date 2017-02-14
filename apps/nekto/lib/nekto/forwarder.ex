defmodule Nekto.Forwarder do
  @moduledoc """
  Forwards messages between clients
  """

  use GenServer

  alias NektoClient.Sender
  alias Nekto.Queue

  ## Client API

  @doc """
  Starts forwarder
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Attaches new client
  """
  def attach_client(forwarder, client, sender) when is_atom(client) do
    GenServer.call(forwarder, {:attach_client, client, sender})
  end

  @doc """
  Deattaches new client
  """
  def deattach_client(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:deattach_client, client})
  end

  @doc """
  Forwards message from client to other client
  """
  def forward_from(forwarder, client, message) when is_atom(client) do
    GenServer.cast(forwarder, {:send, client, message})
  end

  @doc """
  Marks client as connected
  """
  def connect(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:connect, client})
  end

  @doc """
  Marks client as disconnected
  """
  def disconnect(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:disconnect, client})
  end

  @doc """
  Mutes client
  """
  def mute(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:mute, client})
  end

  @doc """
  Unmutes client
  """
  def unmute(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:unmute, client})
  end

  @doc """
  Returns client's queue
  """
  def queue(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:queue, client})
  end

  @doc """
  Returns client connected state
  """
  def connected?(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:connected?, client})
  end

  @doc """
  Returns client muted state
  """
  def muted?(forwarder, client) when is_atom(client) do
    GenServer.call(forwarder, {:muted?, client})
  end

  ## Server Callbacks

  def init(:ok) do
    forwarding_table = :ets.new(:forwarding_table, [:set, :private])
    {:ok, forwarding_table}
  end

  def handle_cast({:send, client, message}, forwarding_table) do
    case :ets.lookup(forwarding_table, client) do
      [{^client, %{muted: false}, _, _}] ->
        forward_broadcast(forwarding_table, client, message)
        {:noreply, forwarding_table}
      _ ->
        {:noreply, forwarding_table}
    end
  end

  def handle_call({:attach_client, client, sender}, _from, forwarding_table) do
    {:ok, queue} = Queue.start_link
    result = :ets.insert_new(
      forwarding_table,
      {client, %{muted: false, connected: false}, sender, queue}
    )
    {:reply, result, forwarding_table}
  end

  def handle_call({:deattach_client, client}, _from, forwarding_table) do
    forwarding_table
    |> lookup(
         client,
         fn({_, _, _, queue}) ->
           Queue.stop(queue)
           :ets.delete(forwarding_table, client)
         end
       )
  end

  def handle_call({:connect, client}, _from, forwarding_table) do
    forwarding_table
    |> lookup(
         client,
         fn({_, _, sender, queue} = row) ->
           update_state(forwarding_table, row, :connected, true)
           send_queue_to(queue, sender)
         end
       )
  end

  def handle_call({:disconnect, client}, _from, ftable) do
    ftable
    |> lookup(
         client, fn(row) -> update_state(ftable, row, :connected, false) end
       )
  end

  def handle_call({:mute, client}, _from, ftable) do
    ftable
    |> lookup(
         client, fn(row) -> update_state(ftable, row, :muted, true) end
       )
  end

  def handle_call({:unmute, client}, _from, ftable) do
    ftable
    |> lookup(
         client, fn(row) -> update_state(ftable, row, :muted, false) end
       )
  end

  def handle_call({:queue, client}, _from, forwarding_table) do
    case :ets.lookup(forwarding_table, client) do
      [{^client, _, _, queue}] ->
        {:reply, {:ok, queue}, forwarding_table}
      [] ->
        {:reply, :not_found, forwarding_table}
    end
  end

  def handle_call({:connected?, client}, _from, forwarding_table) do
    case :ets.lookup(forwarding_table, client) do
      [{^client, %{connected: connected}, _, _}] ->
        {:reply, {:ok, connected}, forwarding_table}
      [] ->
        {:reply, :not_found, forwarding_table}
    end
  end

  def handle_call({:muted?, client}, _from, forwarding_table) do
    case :ets.lookup(forwarding_table, client) do
      [{^client, %{muted: muted}, _, _}] ->
        {:reply, {:ok, muted}, forwarding_table}
      [] ->
        {:reply, :not_found, forwarding_table}
    end
  end

  def terminate(reason, forwarding_table) do
    forwarding_table
    |> :ets.select([{{:_, :_, :_, :"$1"}, [], [:"$1"]}])
    |> Enum.each(fn(queue) -> Queue.stop(queue) end)
    reason
  end


  defp select_all(forwarding_table, except) do
    forwarding_table
    |> :ets.select([{{:"$1", :_, :_, :_}, [{:"/=", :"$1", except}], [:"$_"]}])
  end

  defp forward_broadcast(forwarding_table, client, message) do
    forwarding_table
    |> select_all(client)
    |> Enum.each(fn({_, state, sender, queue}) ->
                   forward_message(state, sender, queue, message)
                 end)
  end

  defp forward_message(%{connected: true}, sender, _, message) do
    Sender.send(sender, message)
  end

  defp forward_message(%{connected: false}, _, queue, message) do
    Queue.put(queue, message)
  end

  defp update_state(forwarding_table,
                    {client, state, sender, queue}, key, value) do
    new_state = Map.merge(state, %{key => value})
    :ets.insert(
      forwarding_table,
      {client, new_state, sender, queue}
    )
  end

  defp lookup(forwarding_table, client, fun) do
    case :ets.lookup(forwarding_table, client) do
      [{^client, _, _, _} = row] ->
        fun.(row)
        {:reply, :ok, forwarding_table}
      [] ->
        {:reply, :not_found, forwarding_table}
    end
  end

  defp send_queue_to(queue, sender) do
    queue
    |> Queue.pop_all
    |> Enum.each(fn message -> Sender.send(sender, message) end)
  end
end

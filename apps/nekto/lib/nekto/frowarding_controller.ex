defmodule Nekto.ForwardingController do
  @moduledoc """
  Controller that controles forwarder
  """

  use GenServer

  ## Client API

  @doc """
  Starts forwarding controller
  """
  def start_link do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  @doc """
  Access forwarding to client
  """
  def forward_from?(controller, client) when client in [:a, :b] do
    GenServer.call(controller, {:forward_from, client})
  end

  @doc """
  Mark client as muted
  """
  def mute(controller, client) when client in [:a, :b] do
    GenServer.call(controller, {:mute, client})
  end

  @doc """
  Mark client as unmuted
  """
  def unmute(controller, client) when client in [:a, :b] do
    GenServer.call(controller, {:unmute, client})
  end

  @doc """
  Mark client as connected
  """
  def connect(controller, client) when client in [:a, :b] do
    GenServer.call(controller, {:connect, client})
  end

  @doc """
  Mark client as disconnected
  """
  def disconnect(controller, client) when client in [:a, :b] do
    GenServer.call(controller, {:disconnect, client})
  end

  ## Server Callbacks

  def init(:ok) do
    state = %{
      a: %{muted: false, connected: false},
      b: %{muted: false, connected: false}
    }
    {:ok, state}
  end

  def handle_call({:forward_from, :a}, _from, state) do
    {:reply, !muted?(state, :a) && connected?(state, :b), state}
  end

  def handle_call({:forward_from, :b}, _from, state) do
    {:reply, !muted?(state, :b) && connected?(state, :a), state}
  end

  def handle_call({:mute, client}, _from, state) do
    {:reply, :ok, update_state(state, client, :muted, true)}
  end

  def handle_call({:unmute, client}, _from, state) do
    {:reply, :ok, update_state(state, client, :muted, false)}
  end

  def handle_call({:connect, client}, _from, state) do
    {:reply, :ok, update_state(state, client, :connected, true)}
  end

  def handle_call({:disconnect, client}, _from, state) do
    {:reply, :ok, update_state(state, client, :connected, false)}
  end

  defp update_state(state, client, key, value) do
    client_value = Map.get(state, client)
    state
    |> Map.put(client, Map.merge(client_value, %{key => value}))
  end

  defp muted?(state, client) do
    state
    |> Map.get(client)
    |> Map.get(:muted)
  end

  defp connected?(state, client) do
    state
    |> Map.get(client)
    |> Map.get(:connected)
  end
end

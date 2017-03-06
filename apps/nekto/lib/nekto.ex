defmodule Nekto do

  alias NektoClient.HTTPClient
  alias NektoClient.Sender
  alias NektoClient.Receiver
  alias NektoClient.Model.Search
  alias Nekto.Supervisor
  alias Nekto.Forwarder

  @clients [:a, :b]

  @doc """
  Starts Nekto.Supervisor
  """
  def start do
    if ws_path do
      Supervisor.start_link(ws_host, path: ws_path)
    else
      Supervisor.start_link(ws_host)
    end
  end

  @doc """
  Stops Nekto.Supervisor
  """
  def stop(supervisor) do
    Supervisor.stop(supervisor)
  end

  @doc """
  Restarts Nekto.Supervisor
  """
  def restart(supervisor) do
    stop(supervisor)
    start
  end

  @doc """
  Adds handler to client's receiver
  """
  def add_handler(supervisor, client, handler, args) do
    supervisor
    |> Supervisor.receiver(client)
    |> Receiver.add_handler(handler, args)
  end

  @doc """
  Removes handler from client's receiver
  """
  def remove_handler(supervisor, client, handler, args) do
    supervisor
    |> Supervisor.receiver(client)
    |> Receiver.remove_handler(handler, args)
  end

  @doc """
  Authenticates all clients
  """
  def authenticate(supervisor) do
    @clients
    |> Enum.each(fn(client) -> authenticate(supervisor, client) end)
  end

  @doc """
  Authenticates client
  """
  def authenticate(supervisor, client) do
    supervisor
    |> Supervisor.sender(client)
    |> Sender.authenticate(HTTPClient.chat_token!(host))
  end

  @doc """
  Starts listening all clients
  """
  def start_listening(supervisor) do
    @clients
    |> Enum.each(fn(client) -> start_listening(supervisor, client) end)
  end

  @doc """
  Starts listening client
  """
  def start_listening(supervisor, client) do
    supervisor
    |> Supervisor.receiver(client)
    |> Receiver.start_listening
  end

  @doc """
  Starts search for client
  """
  def search(supervisor, client, params) do
    IO.puts inspect(Search.from_hash(params))
    supervisor
    |> Supervisor.sender(client)
    |> Sender.search(Search.from_hash(params))
  end

  @doc """
  Kicks all clients
  """
  def kick(supervisor) do
    @clients
    |> Enum.each(fn(client) -> kick(supervisor, client) end)
  end

  @doc """
  Kicks client
  """
  def kick(supervisor, client) do
    supervisor
    |> Supervisor.sender(client)
    |> Sender.leave_dialog
  end

  @doc """
  Sends message to all client (broadcast)
  """
  def send(supervisor, message) do
    @clients
    |> Enum.each(fn(client) -> send(supervisor, client, message) end)
  end

  @doc """
  Sends message to client
  """
  def send(supervisor, client, message) do
    supervisor
    |> Supervisor.sender(client)
    |> Sender.send(message)
  end

  @doc """
  Mutes all clients
  """
  def mute(supervisor) do
    @clients
    |> Enum.each(fn(client) -> mute(supervisor, client) end)
  end

  @doc """
  Mutes client
  """
  def mute(supervisor, client) do
    supervisor
    |> Supervisor.forwarder
    |> Forwarder.mute(client)
  end

  @doc """
  Unmutes all clients
  """
  def unmute(supervisor) do
    @clients
    |> Enum.each(fn(client) -> unmute(supervisor, client) end)
  end

  @doc """
  Unmutes client
  """
  def unmute(supervisor, client) do
    supervisor
    |> Supervisor.forwarder
    |> Forwarder.unmute(client)
  end

  @doc """
  Returns client connection state
  """
  def connected?(supervisor, client) do
    supervisor
    |> Supervisor.forwarder
    |> Forwarder.connected?(client)
  end

  @doc """
  Returns client mute state
  """
  def muted?(supervisor, client) do
    supervisor
    |> Supervisor.forwarder
    |> Forwarder.muted?(client)
  end


  defp host do
    Application.get_env(:nekto, :host)
  end

  defp ws_host do
    Application.get_env(:nekto, :ws_host)
  end

  defp ws_path do
    Application.get_env(:nekto, :ws_path)
  end
end

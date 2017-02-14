defmodule Nekto.Supervisor do
  @moduledoc """
  Supervisor for supervising two Nekto clients (A and B)
  """

  use Supervisor
  alias NektoClient.Receiver
  alias Nekto.Forwarder
  alias Nekto.MessagesHandler

  @doc """
  Starts supervisor (client A and B) and registers forwarder handler
  """
  def start_link(host) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, [host]})
    prepare_clients(pid)
    {:ok, pid}
  end

  @doc """
  Starts supervisor (clients A and B) and registers forwarder handler
  """
  def start_link(host, args) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, [host, args]})
    prepare_clients(pid)
    {:ok, pid}
  end

  @doc """
  Stops the supervisor and it's children
  """
  def stop(supervisor, reason \\ :normal) do
    Supervisor.stop(supervisor, reason)
  end

  @doc """
  Returns pid of Nekto Client
  """
  def client(supervisor, client) when is_atom(client) do
    supervisor
    |> which_child("NektoClient.Supervisor.#{client}")
    |> elem(1)
  end

  @doc """
  Returns pid of Nekto Client Sender
  """
  def sender(supervisor, client) when is_atom(client) do
    supervisor
    |> client(client)
    |> NektoClient.Supervisor.sender
  end

  @doc """
  Returns pid of Nekto Client Receiver
  """
  def receiver(supervisor, client) when is_atom(client) do
    supervisor
    |> client(client)
    |> NektoClient.Supervisor.receiver
  end

  @doc """
  Returns forwarding controller pid
  """
  def forwarder(supervisor) do
    supervisor
    |> which_child(Forwarder)
    |> elem(1)
  end

  @doc """
  Returns child by module name
  """
  def which_child(supervisor, worker) do
    supervisor
    |> Supervisor.which_children
    |> List.keyfind(worker, 0)
  end

  def init({:ok, params}) do
    children = [
      supervisor(NektoClient.Supervisor, params,
                 id: "NektoClient.Supervisor.a"),
      supervisor(NektoClient.Supervisor, params,
                 id: "NektoClient.Supervisor.b"),
      worker(Forwarder, [])
    ]

    supervise(children, strategy: :one_for_one)
  end


  defp prepare_clients(supervisor) do
    forwarder = forwarder(supervisor)
    [:a, :b]
    |> Enum.map(fn(c) -> {c, client(supervisor, c)} end)
    |> Enum.each(fn(client_data) -> prepare_client(forwarder, client_data) end)
  end

  defp prepare_client(forwarder, {client_name, client}) do
    Forwarder.attach_client(forwarder, client_name,
                            NektoClient.Supervisor.sender(client))
    Receiver.add_handler(
      NektoClient.Supervisor.receiver(client),
      MessagesHandler, %{client: client_name, forwarder: forwarder}
    )
  end
end

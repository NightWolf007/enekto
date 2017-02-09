defmodule Nekto.Supervisor do
  @moduledoc """
  Supervisor for supervising two Nekto clients (A and B)
  """

  use Supervisor
  alias NektoClient.Sender
  alias NektoClient.Receiver
  alias NektoClient.HTTPClient
  alias Nekto.Forwarder

  @doc """
  Starts supervisor (client A and B) and registers forwarder handler
  """
  def start_link(host) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, host})
    register_forwarder(pid)
    {:ok, pid}
  end

  @doc """
  Starts supervisor (clients A and B) and registers forwarder handler
  """
  def start_link(host, args) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, host, args})
    register_forwarder(pid)
    {:ok, pid}
  end

  @doc """
  Stops the supervisor and it's children
  """
  def stop(supervisor, reason \\ :normal) do
    Supervisor.stop(supervisor, reason)
  end

  @doc """
  Returns pid of Nekto Client A
  """
  def client_a(supervisor) do
    supervisor
    |> which_child("NektoClient.Supervisor.A")
    |> elem(1)
  end

  def client_a_sender(supervisor) do
    supervisor
    |> client_a
    |> NektoClient.Supervisor.sender
  end

  def client_a_receiver(supervisor) do
    supervisor
    |> client_a
    |> NektoClient.Supervisor.receiver
  end

  @doc """
  Returns pid of Nekto Client B
  """
  def client_b(supervisor) do
    supervisor
    |> which_child("NektoClient.Supervisor.B")
    |> elem(1)
  end

  def client_b_sender(supervisor) do
    supervisor
    |> client_b
    |> NektoClient.Supervisor.sender
  end

  def client_b_receiver(supervisor) do
    supervisor
    |> client_b
    |> NektoClient.Supervisor.receiver
  end

  @doc """
  Returns child by module name
  """
  def which_child(supervisor, worker) do
    supervisor
    |> Supervisor.which_children
    |> List.keyfind(worker, 0)
  end

  @doc """
  Starts listenning sockets on both receivers
  """
  def start_listening(supervisor) do
    supervisor
    |> client_a_receiver
    |> Receiver.start_listening

    supervisor
    |> client_b_receiver
    |> Receiver.start_listening
  end

  @doc """
  Auto authenticate two clients
  """
  def authenticate(supervisor, host) do
    supervisor
    |> client_a_sender
    |> Sender.authenticate(HTTPClient.chat_token!(host))

    supervisor
    |> client_b_sender
    |> Sender.authenticate(HTTPClient.chat_token!(host))
  end

  def init({:ok, host}) do
    children = [
      supervisor(NektoClient.Supervisor, [host],
                 id: "NektoClient.Supervisor.A"),
      supervisor(NektoClient.Supervisor, [host],
                 id: "NektoClient.Supervisor.B")
    ]

    supervise(children, strategy: :one_for_one)
  end

  def init({:ok, host, args}) do
    children = [
      supervisor(NektoClient.Supervisor, [host, args],
                 id: "NektoClient.Supervisor.A"),
      supervisor(NektoClient.Supervisor, [host, args],
                 id: "NektoClient.Supervisor.B")
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp register_forwarder(supervisor) do
    supervisor
    |> client_a_receiver
    |> Receiver.add_handler(Forwarder, client_b_sender(supervisor))

    supervisor
    |> client_b_receiver
    |> Receiver.add_handler(Forwarder, client_a_sender(supervisor))
  end
end

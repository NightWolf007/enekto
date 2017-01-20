defmodule NektoClient.Supervisor do
  use Supervisor

  @doc """
  Starts supervisor (sender and receiver)
  and establishes socket connection with host
  """
  def start_link(host) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, host})
    NektoClient.Receiver.add_handler(receiver(pid), NektoClient.Handler, sender(pid))
    {:ok, pid}
  end

  @doc """
  Starts supervisor (sender and receiver)
  and establishes socket connection with host with args
  args - Socket.Web.connect method args
  """
  def start_link(host, args) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, host, args})
    NektoClient.Receiver.add_handler(receiver(pid), NektoClient.Handler, sender(pid))
    {:ok, pid}
  end

  @doc """
  Returns sender pid
  """
  def sender(supervisor) do
    supervisor
    |> which_child(NektoClient.Sender)
    |> elem(1)
  end

  @doc """
  Returns receiver pid
  """
  def receiver(supervisor) do
    supervisor
    |> which_child(NektoClient.Receiver)
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

  def init({:ok, host}) do
    socket = NektoClient.WSClient.connect!(host)
    init_children(socket)
  end

  def init({:ok, host, args}) do
    socket = NektoClient.WSClient.connect!(host, args)
    init_children(socket)
  end

  defp init_children(socket) do
    children = [
      worker(NektoClient.Sender, [socket]),
      worker(NektoClient.Receiver, [socket])
    ]

    supervise(children, strategy: :one_for_one)
  end
end

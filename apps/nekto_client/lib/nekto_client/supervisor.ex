defmodule NektoClient.Supervisor do
  use Supervisor

  def start_link(host) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, host})
    NektoClient.Receiver.add_handler(receiver(pid), NektoClient.Handler, sender(pid))
    {:ok, pid}
  end

  def start_link(host, args) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, {:ok, host, args})
    NektoClient.Receiver.add_handler(receiver(pid), NektoClient.Handler, sender(pid))
    {:ok, pid}
  end

  def sender(supervisor) do
    supervisor
    |> which_child(NektoClient.Sender)
    |> elem(1)
  end

  def receiver(supervisor) do
    supervisor
    |> which_child(NektoClient.Receiver)
    |> elem(1)
  end

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

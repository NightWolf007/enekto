defmodule NektoClient.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
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

  def init(:ok) do
    socket = NektoClient.WSClient.connect!

    children = [
      worker(NektoClient.Sender, [socket]),
      worker(NektoClient.Receiver, [socket])
    ]

    supervise(children, strategy: :one_for_all)
  end
end

defmodule NektoBot.Supervisor do
  @moduledoc """
  Supervisor for supervising NektoBot Receiver and Controller
  """

  use Supervisor
  alias NektoBot.Controller
  alias NektoBot.Receiver
  alias NektoBot.MessagesHandler

  @doc """
  Starts supervisor and registers messages handler
  """
  def start_link do
    {:ok, pid} = Supervisor.start_link(__MODULE__, :ok)
    pid
    |> receiver
    |> Receiver.add_handler(MessagesHandler, %{controller: controller(pid)})
    {:ok, pid}
  end

  @doc """
  Returns pid of Controller
  """
  def controller(supervisor) do
    supervisor
    |> which_child(Controller)
    |> elem(1)
  end

  @doc """
  Returns pid of Receiver
  """
  def receiver(supervisor) do
    supervisor
    |> which_child(Receiver)
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

  def init(:ok) do
    children = [
      worker(Controller, []),
      worker(Receiver, [])
    ]

    supervise(children, strategy: :one_for_one, name: NektoBot.Supervisor)
  end
end

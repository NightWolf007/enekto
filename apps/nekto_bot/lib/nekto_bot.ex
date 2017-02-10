defmodule NektoBot do
  use Application

  alias NektoBot.Supervisor
  alias NektoBot.Receiver

  def start(_type, _args) do
    {:ok, pid} = Supervisor.start_link
    pid
    |> Supervisor.receiver
    |> Receiver.start_listening
    {:ok, pid}
  end
end

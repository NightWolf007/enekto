defmodule NektoClient.Sender do
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, {:ok, socket}, [])
  end

  def authenticate(sender, user_token) do
    GenServer.call(sender, {:authenticate, user_token})
  end

  def init({:ok, socket}) do
    {:ok, %{socket: socket}}
  end

  def handle_call({:authenticate, user_token}, _from, state) do
    state
    |> Map.get(:socket)
    |> NektoClient.WSClient.auth!(user_token)
  end
end

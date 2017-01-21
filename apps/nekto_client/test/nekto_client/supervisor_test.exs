defmodule NektoClient.SupervisorTest do
  use ExUnit.Case, async: true

  alias Support.WSServerMock
  alias Support.Handler
  alias NektoClient.Supervisor
  alias NektoClient.Receiver

  setup do{:ok, mock_server} = WSServerMock.start_link
  WSServerMock.start(mock_server, 9000)

  {:ok, supervisor} =
    Supervisor.start_link({"localhost", 9000}, path: "/")

  {:ok, supervisor: supervisor}
  end

  test "it starts link with args", %{supervisor: supervisor} do
    receiver = Supervisor.receiver(supervisor)

    Receiver.add_handler(receiver, Handler, [])
    gen_event = Receiver.gen_event(receiver)

    Receiver.start_listening(receiver)

    assert Handler.wait(gen_event) == {:success_connected, %{}}
  end

  test "it returns sender", %{supervisor: supervisor} do
    assert Supervisor.sender(supervisor) != nil
  end

  test "it returns receiver", %{supervisor: supervisor} do
    assert Supervisor.receiver(supervisor) != nil
  end
end

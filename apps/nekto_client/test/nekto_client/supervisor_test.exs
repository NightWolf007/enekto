defmodule NektoClient.SupervisorTest do
  use ExUnit.Case, async: true

  test "it starts link with args" do
    {:ok, mock_server} = Support.WSServerMock.start_link
    Support.WSServerMock.start(mock_server, 9000)

    {:ok, supervisor} =
      NektoClient.Supervisor.start_link({"localhost", 9000}, path: "/")

    receiver = NektoClient.Supervisor.receiver(supervisor)

    NektoClient.Receiver.add_handler(receiver, Support.Handler, [])
    gen_event = NektoClient.Receiver.gen_event(receiver)

    NektoClient.Receiver.start_listening(receiver)

    assert Support.Handler.wait(gen_event) == {:success_connected, %{}}
  end
end

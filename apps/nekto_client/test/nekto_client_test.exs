defmodule NektoClientTest do
  use ExUnit.Case

  setup do
    {:ok, mock_server} = Support.WSServerMock.start_link
    Support.WSServerMock.start(mock_server, 9000)

    {:ok, supervisor} = NektoClient.Supervisor.start_link({"localhost", 9000})
    sender = NektoClient.Supervisor.sender(supervisor)
    receiver = NektoClient.Supervisor.receiver(supervisor)

    NektoClient.Receiver.add_handler(receiver, Support.Handler, [])
    gen_event = NektoClient.Receiver.gen_event(receiver)

    NektoClient.Receiver.start_listening(receiver)

    {:ok, sender: sender, receiver: receiver, gen_event: gen_event}
  end

  test "it handles success_connected message", %{gen_event: gen_event} do
    assert Support.Handler.wait(gen_event) == {:success_connected, %{}}
  end

  test "it counts online users", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.count_online_users(sender)
    assert Support.Handler.wait(gen_event) == {:count_online_users, %{"count" => 1000}}
    assert Support.Handler.wait(gen_event) == {:count_insearch_users, %{"count" => 100}}
  end

  test "it authenticates user", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.authenticate(sender, "user_token")
    assert Support.Handler.wait(gen_event) == {:success_auth, %NektoClient.Model.User{id: 12345}}
  end
end

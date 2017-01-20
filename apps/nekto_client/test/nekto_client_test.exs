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
    assert Support.Handler.wait(gen_event) ==
      {:success_auth, %NektoClient.Model.User{id: 12345}}
  end

  test "it searches company", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)

    search_params = %NektoClient.Model.Search{my_sex: "M", wish_sex: "F",
                                              my_age_from: 18, my_age_to: 21,
                                              wish_age: ["0t17", "18t21"]}
    :ok = NektoClient.Sender.search(sender, search_params)
    assert Support.Handler.wait(gen_event) ==
      {:open_dialog, %NektoClient.Model.Dialog{id: 10, uids: [12345, 67890]}}
  end

  test "it sends typing status", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.authenticate(sender, "")
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.search(sender, %NektoClient.Model.Search{})
    Support.Handler.wait(gen_event)

    :ok = NektoClient.Sender.typing(sender, true)
    assert Support.Handler.wait(gen_event) == {:typing_a_message, %{}}
  end

  test "it sends message", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.authenticate(sender, "")
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.search(sender, %NektoClient.Model.Search{})
    Support.Handler.wait(gen_event)

    :ok = NektoClient.Sender.send(sender, "test message 1")
    assert Support.Handler.wait(gen_event) ==
      {:success_send_message, %{"message_id" => 11111}}
    :ok = NektoClient.Sender.send(sender, "test message 2")
    assert Support.Handler.wait(gen_event) ==
      {:success_send_message, %{"message_id" => 22222}}
  end

  test "it reads messages", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.authenticate(sender, "")
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.search(sender, %NektoClient.Model.Search{})
    Support.Handler.wait(gen_event)

    messages = [
      %NektoClient.Model.Message{id: 1},
      %NektoClient.Model.Message{id: 2},
      %NektoClient.Model.Message{id: 3}
    ]

    :ok = NektoClient.Sender.read_messages(sender, messages)
    assert Support.Handler.wait(gen_event) == {:chat_message_read, %{}}
  end

  test "it leaves search", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.authenticate(sender, "")
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.search(sender, %NektoClient.Model.Search{})
    Support.Handler.wait(gen_event)

    :ok = NektoClient.Sender.leave_search(sender)
    assert Support.Handler.wait(gen_event) == {:out_search_company, %{}}
  end

  test "it leaves dialog", %{sender: sender, gen_event: gen_event} do
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.authenticate(sender, "")
    Support.Handler.wait(gen_event)
    :ok = NektoClient.Sender.search(sender, %NektoClient.Model.Search{})
    Support.Handler.wait(gen_event)

    :ok = NektoClient.Sender.leave_dialog(sender)
    assert Support.Handler.wait(gen_event) ==
      {:success_leave, %{"dialog_id" => 100}}
  end
end

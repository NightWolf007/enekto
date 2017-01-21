defmodule NektoClientTest do
  use ExUnit.Case, async: true

  alias Support.WSServerMock
  alias Support.Handler
  alias NektoClient.Supervisor
  alias NektoClient.Sender
  alias NektoClient.Receiver
  alias Socket.Web

  setup do
    {:ok, mock_server} = WSServerMock.start_link
    WSServerMock.start(mock_server, 9000)

    {:ok, supervisor} = Supervisor.start_link({"localhost", 9000})
    sender = Supervisor.sender(supervisor)
    receiver = Supervisor.receiver(supervisor)

    Receiver.add_handler(receiver, Handler, [])
    gen_event = Receiver.gen_event(receiver)

    Receiver.start_listening(receiver)

    {:ok, sender: sender, receiver: receiver, gen_event: gen_event}
  end

  test "it handles success_connected message", %{gen_event: gen_event} do
    assert Handler.wait(gen_event) == {:success_connected, %{}}
  end

  test "it counts online users", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)

    :ok = Sender.count_online_users(sender)
    assert Handler.wait(gen_event) == {:count_online_users, %{"count" => 1000}}
    assert Handler.wait(gen_event) == {:count_insearch_users, %{"count" => 100}}
  end

  test "it authenticates user", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)

    :ok = Sender.authenticate(sender, "user_token")
    assert Handler.wait(gen_event) ==
      {:success_auth, %NektoClient.Model.User{id: 12_345}}
  end

  test "it searches company", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)

    search_params = %NektoClient.Model.Search{my_sex: "M", wish_sex: "F",
                                              my_age_from: 18, my_age_to: 21,
                                              wish_age: ["0t17", "18t21"]}
    :ok = Sender.search(sender, search_params)
    assert Handler.wait(gen_event) ==
      {:open_dialog, %NektoClient.Model.Dialog{id: 10, uids: [12_345, 67_890]}}
  end

  test "it sends typing status", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    :ok = Sender.authenticate(sender, "")
    Handler.wait(gen_event)
    :ok = Sender.search(sender, %NektoClient.Model.Search{})
    Handler.wait(gen_event)

    :ok = Sender.typing(sender, true)
    assert Handler.wait(gen_event) == {:typing_a_message, %{}}
  end

  test "it sends message", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    :ok = Sender.authenticate(sender, "")
    Handler.wait(gen_event)
    :ok = Sender.search(sender, %NektoClient.Model.Search{})
    Handler.wait(gen_event)

    :ok = Sender.send(sender, "test message 1")
    assert Handler.wait(gen_event) ==
      {:success_send_message, %{"message_id" => 11_111}}
    :ok = Sender.send(sender, "test message 2")
    assert Handler.wait(gen_event) ==
      {:success_send_message, %{"message_id" => 22_222}}
  end

  test "it reads messages", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    :ok = Sender.authenticate(sender, "")
    Handler.wait(gen_event)
    :ok = Sender.search(sender, %NektoClient.Model.Search{})
    Handler.wait(gen_event)

    messages = [
      %NektoClient.Model.Message{id: 1},
      %NektoClient.Model.Message{id: 2},
      %NektoClient.Model.Message{id: 3}
    ]

    :ok = Sender.read_messages(sender, messages)
    assert Handler.wait(gen_event) == {:chat_message_read, %{}}
  end

  test "it leaves search", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    :ok = Sender.authenticate(sender, "")
    Handler.wait(gen_event)
    :ok = Sender.search(sender, %NektoClient.Model.Search{})
    Handler.wait(gen_event)

    :ok = Sender.leave_search(sender)
    assert Handler.wait(gen_event) == {:out_search_company, %{}}
  end

  test "it leaves dialog", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    :ok = Sender.authenticate(sender, "")
    Handler.wait(gen_event)
    :ok = Sender.search(sender, %NektoClient.Model.Search{})
    Handler.wait(gen_event)

    :ok = Sender.leave_dialog(sender)
    assert Handler.wait(gen_event) ==
      {:success_leave, %{"dialog_id" => 100}}
  end

  test "it sends pong on receiving ping",
       %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    sender
    |> Sender.get_socket
    |> Web.send!({:text, Poison.encode!(%{test: "ping"})})

    assert Handler.wait(gen_event) == {:pong, %{}}
  end

  test "it handles chat_new_message", %{sender: sender, gen_event: gen_event} do
    Handler.wait(gen_event)
    :ok = Sender.authenticate(sender, "")
    Handler.wait(gen_event)
    :ok = Sender.search(sender, %NektoClient.Model.Search{})
    Handler.wait(gen_event)

    sender
    |> Sender.get_socket
    |> Web.send!({:text, Poison.encode!(%{test: "chat_new_message"})})

    assert Handler.wait(gen_event) == {
      :chat_new_message,
      %NektoClient.Model.Message{id: 33_333, dialog_id: 100,
                                 uid: 98_765, text: "test message"}
    }
  end
end

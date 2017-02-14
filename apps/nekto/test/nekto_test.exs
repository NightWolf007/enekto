defmodule NektoTest do
  use ExUnit.Case, async: true

  import Mock

  alias Socket.Web
  alias NektoClient.HTTPClient
  alias NektoClient.Sender
  alias NektoClient.Receiver
  alias NektoClient.Model.Search
  alias Nekto.Supervisor
  alias Nekto.Forwarder

  setup do
    Mix.Config.persist(
      nekto: [
        host: "host.com",
        ws_host: "ws_host.com",
        ws_path: "/websocket"
      ]
    )
    with_mock Web, [connect!: fn(_, _) -> "socket" end] do
      {:ok, nekto} = Nekto.start
      {
        :ok,
        nekto: nekto,
        sender_a: Supervisor.sender(nekto, :a),
        sender_b: Supervisor.sender(nekto, :b),
        receiver_a: Supervisor.receiver(nekto, :a),
        receiver_b: Supervisor.receiver(nekto, :b),
        forwarder: Supervisor.forwarder(nekto)
      }
    end
  end

  describe "Nekto.start/1" do
    test "it starts Nekto.Supervisor with ws host" do
      Mix.Config.persist(
        nekto: [
          host: "host.com",
          ws_host: "ws_host.com",
          ws_path: nil
        ]
      )
      with_mock Supervisor, [start_link: fn(_) -> {:ok, "pid"} end] do
        {:ok, "pid"} = Nekto.start
        assert called Supervisor.start_link("ws_host.com")
      end
    end

    test "it starts Nekto.Supervisor with ws host and path" do
      Mix.Config.persist(
        nekto: [
          host: "host.com",
          ws_host: "ws_host.com",
          ws_path: "/websocket"
        ]
      )
      with_mock Supervisor, [start_link: fn(_, _) -> {:ok, "pid"} end] do
        {:ok, "pid"} = Nekto.start
        assert called Supervisor.start_link("ws_host.com", path: "/websocket")
      end
    end
  end

  describe "Nekto.stop/1" do
    test "it stops Nekto.Supervisor", %{nekto: nekto} do
      ref = Process.monitor(nekto)
      Nekto.stop(nekto)
      assert_receive {:DOWN, ^ref, _, _, _}
    end
  end

  describe "Nekto.restart/1" do
    test "it restarts Nekto.Supervisor with ws host", %{nekto: nekto} do
      Mix.Config.persist(
        nekto: [
          host: "host.com",
          ws_host: "ws_host.com",
          ws_path: nil
        ]
      )
      with_mock Supervisor,
                [start_link: fn(_) -> {:ok, "pid"} end,
                 stop: fn(s) -> Elixir.Supervisor.stop(s) end] do
        ref = Process.monitor(nekto)
        {:ok, "pid"} = Nekto.restart(nekto)

        assert_receive {:DOWN, ^ref, _, _, _}
        assert called Supervisor.start_link("ws_host.com")
      end
    end

    test "it restarts Nekto.Supervisor with ws host and path",
         %{nekto: nekto} do
      Mix.Config.persist(
        nekto: [
          host: "host.com",
          ws_host: "ws_host.com",
          ws_path: "/websocket"
        ]
      )
      with_mock Supervisor,
                [start_link: fn(_, _) -> {:ok, "pid"} end,
                 stop: fn(s) -> Elixir.Supervisor.stop(s) end] do
        ref = Process.monitor(nekto)
        {:ok, "pid"} = Nekto.restart(nekto)

        assert_receive {:DOWN, ^ref, _, _, _}
        assert called Supervisor.start_link("ws_host.com", path: "/websocket")
      end
    end
  end

  describe "Nekto.add_handler/4" do
    test "it adds handler to receiver A", %{nekto: nekto} do
      gen_event = nekto |> Supervisor.receiver(:a) |> Receiver.gen_event
      Nekto.add_handler(nekto, :a, Handler, %{})
      assert Handler in GenEvent.which_handlers(gen_event)
    end

    test "it adds handler to receiver B", %{nekto: nekto} do
      gen_event = nekto |> Supervisor.receiver(:b) |> Receiver.gen_event
      Nekto.add_handler(nekto, :b, Handler, %{})
      assert Handler in GenEvent.which_handlers(gen_event)
    end
  end

  describe "Nekto.remove_handler/4" do
    test "it removes handler to receiver A", %{nekto: nekto} do
      gen_event = nekto |> Supervisor.receiver(:a) |> Receiver.gen_event
      Nekto.add_handler(nekto, :a, Handler, %{})
      assert Handler in GenEvent.which_handlers(gen_event)

      Nekto.remove_handler(nekto, :a, Handler, %{})
      refute Handler in GenEvent.which_handlers(gen_event)
    end

    test "it removes handler to receiver B", %{nekto: nekto} do
      gen_event = nekto |> Supervisor.receiver(:b) |> Receiver.gen_event
      Nekto.add_handler(nekto, :b, Handler, %{})
      assert Handler in GenEvent.which_handlers(gen_event)

      Nekto.remove_handler(nekto, :b, Handler, %{})
      refute Handler in GenEvent.which_handlers(gen_event)
    end
  end

  describe "Nekto.authenticate/1" do
    test "it authenticates both clients",
         %{nekto: nekto, sender_a: sender_a, sender_b: sender_b} do
      with_mocks([
        {HTTPClient, [], [chat_token!: fn _ -> "abc12345" end]},
        {Sender, [], [authenticate: fn(_,_) -> :ok end]}
      ]) do
        :ok = Nekto.authenticate(nekto)
        assert called HTTPClient.chat_token!("host.com")
        assert called Sender.authenticate(sender_a, "abc12345")

        assert called HTTPClient.chat_token!("host.com")
        assert called Sender.authenticate(sender_b, "abc12345")
      end
    end
  end

  describe "Nekto.authenticate/2" do
    test "it authenticates client A", %{nekto: nekto, sender_a: sender} do
      with_mocks([
        {HTTPClient, [], [chat_token!: fn _ -> "abc12345" end]},
        {Sender, [], [authenticate: fn(_,_) -> :ok end]}
      ]) do
        :ok = Nekto.authenticate(nekto, :a)
        assert called HTTPClient.chat_token!("host.com")
        assert called Sender.authenticate(sender, "abc12345")
      end
    end

    test "it authenticates client B", %{nekto: nekto, sender_b: sender} do
      with_mocks([
        {HTTPClient, [], [chat_token!: fn _ -> "abc12345" end]},
        {Sender, [], [authenticate: fn(_,_) -> :ok end]}
      ]) do
        :ok = Nekto.authenticate(nekto, :b)
        assert called HTTPClient.chat_token!("host.com")
        assert called Sender.authenticate(sender, "abc12345")
      end
    end
  end

  describe "Nekto.start_listening/1" do
    test "it start listening on both receivers",
         %{nekto: nekto, receiver_a: receiver_a, receiver_b: receiver_b} do
      with_mock Receiver, [start_listening: fn _ -> :ok end] do
        :ok = Nekto.start_listening(nekto)
        assert called Receiver.start_listening(receiver_a)
        assert called Receiver.start_listening(receiver_b)
      end
    end
  end

  describe "Nekto.start_listening/2" do
    test "it start listening on receiver A",
         %{nekto: nekto, receiver_a: receiver} do
      with_mock Receiver, [start_listening: fn _ -> :ok end] do
        :ok = Nekto.start_listening(nekto, :a)
        assert called Receiver.start_listening(receiver)
      end
    end

    test "it start listening on receiver B",
         %{nekto: nekto, receiver_b: receiver} do
      with_mock Receiver, [start_listening: fn _ -> :ok end] do
        :ok = Nekto.start_listening(nekto, :b)
        assert called Receiver.start_listening(receiver)
      end
    end
  end

  describe "Nekto.search/3" do
    test "it starts searching for client A",
         %{nekto: nekto, sender_a: sender} do
      with_mock Sender, [search: fn(_, _) -> :ok end] do
        params = %{my_sex: 'M', wish_sex: 'W'}
        :ok = Nekto.search(nekto, :a, params)
        assert called Sender.search(sender, Search.from_hash(params))
      end
    end

    test "it starts searching for client B",
         %{nekto: nekto, sender_b: sender} do
      with_mock Sender, [search: fn(_, _) -> :ok end] do
        params = %{my_sex: 'M', wish_sex: 'W'}
        :ok = Nekto.search(nekto, :b, params)
        assert called Sender.search(sender, Search.from_hash(params))
      end
    end
  end

  describe "Nekto.kick/1" do
    test "it kicks both clients",
         %{nekto: nekto, sender_a: sender_a, sender_b: sender_b} do
      with_mock Sender, [leave_dialog: fn _ -> :ok end] do
        :ok = Nekto.kick(nekto)
        assert called Sender.leave_dialog(sender_a)
        assert called Sender.leave_dialog(sender_b)
      end
    end
  end

  describe "Nekto.kick/2" do
    test "it kicks client A",
         %{nekto: nekto, sender_a: sender} do
      with_mock Sender, [leave_dialog: fn _ -> :ok end] do
        :ok = Nekto.kick(nekto)
        assert called Sender.leave_dialog(sender)
      end
    end

    test "it kicks client B",
         %{nekto: nekto, sender_b: sender} do
      with_mock Sender, [leave_dialog: fn _ -> :ok end] do
        :ok = Nekto.kick(nekto)
        assert called Sender.leave_dialog(sender)
      end
    end
  end

  describe "Nekto.send/2" do
    test "it sends message to both clients",
         %{nekto: nekto, sender_a: sender_a, sender_b: sender_b} do
      with_mock Sender, [send: fn(_, _) -> :ok end] do
        :ok = Nekto.send(nekto, "message")
        assert called Sender.send(sender_a, "message")
        assert called Sender.send(sender_b, "message")
      end
    end
  end

  describe "Nekto.send/3" do
    test "it sends message to client A",
         %{nekto: nekto, sender_a: sender} do
      with_mock Sender, [send: fn(_, _) -> :ok end] do
        :ok = Nekto.send(nekto, :a, "message")
        assert called Sender.send(sender, "message")
      end
    end

    test "it sends message to client B",
         %{nekto: nekto, sender_b: sender} do
      with_mock Sender, [send: fn(_, _) -> :ok end] do
        :ok = Nekto.send(nekto, :b, "message")
        assert called Sender.send(sender, "message")
      end
    end
  end

  describe "Nekto.mute/1" do
    test "it mutes both clients", %{nekto: nekto, forwarder: forwarder} do
      :ok = Nekto.mute(nekto)
      assert Forwarder.muted?(forwarder, :a) == {:ok, true}
      assert Forwarder.muted?(forwarder, :b) == {:ok, true}
    end
  end

  describe "Nekto.mute/2" do
    test "it mutes client A", %{nekto: nekto, forwarder: forwarder} do
      :ok = Nekto.mute(nekto, :a)
      assert Forwarder.muted?(forwarder, :a) == {:ok, true}
    end

    test "it mutes client B", %{nekto: nekto, forwarder: forwarder} do
      :ok = Nekto.mute(nekto, :b)
      assert Forwarder.muted?(forwarder, :b) == {:ok, true}
    end
  end

  describe "Nekto.unmute/1" do
    test "it mutes both clients", %{nekto: nekto, forwarder: forwarder} do
      :ok = Nekto.mute(nekto)
      :ok = Nekto.unmute(nekto)
      assert Forwarder.muted?(forwarder, :a) == {:ok, false}
      assert Forwarder.muted?(forwarder, :b) == {:ok, false}
    end
  end

  describe "Nekto.unmute/2" do
    test "it mutes client A", %{nekto: nekto, forwarder: forwarder} do
      :ok = Nekto.mute(nekto, :a)
      :ok = Nekto.unmute(nekto, :a)
      assert Forwarder.muted?(forwarder, :a) == {:ok, false}
    end

    test "it mutes client B", %{nekto: nekto, forwarder: forwarder} do
      :ok = Nekto.mute(nekto, :b)
      :ok = Nekto.unmute(nekto, :b)
      assert Forwarder.muted?(forwarder, :b) == {:ok, false}
    end
  end

  describe "Nekto.connected?/2" do
    test "it returns true if client connected",
         %{nekto: nekto, forwarder: forwarder} do
      :ok = Forwarder.connect(forwarder, :a)
      assert Nekto.connected?(nekto, :a) == {:ok, true}
    end

    test "it returns false if client disconnected",
         %{nekto: nekto, forwarder: forwarder} do
      :ok = Forwarder.disconnect(forwarder, :a)
      assert Nekto.connected?(nekto, :a) == {:ok, false}
    end
  end

  describe "Nekto.muted?/2" do
    test "it returns true if client muted", %{nekto: nekto} do
      :ok = Nekto.mute(nekto, :a)
      assert Nekto.muted?(nekto, :a) == {:ok, true}
    end

    test "it returns false if client unmuted", %{nekto: nekto} do
      :ok = Nekto.unmute(nekto, :a)
      assert Nekto.muted?(nekto, :a) == {:ok, false}
    end
  end
end

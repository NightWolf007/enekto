defmodule Nekto.ForwarderTest do
  use ExUnit.Case, async: false

  import Mock

  alias NektoClient.Sender
  alias Nekto.Forwarder
  alias Nekto.Queue

  setup do
    {:ok, forwarder} = Forwarder.start_link
    Forwarder.attach_client(forwarder, :a, "PID#senderA")
    Forwarder.attach_client(forwarder, :b, "PID#senderB")
    Forwarder.attach_client(forwarder, :c, "PID#senderC")
    Forwarder.connect(forwarder, :a)
    Forwarder.connect(forwarder, :b)
    Forwarder.connect(forwarder, :c)
    {:ok, queue_a} = Forwarder.queue(forwarder, :a)
    {:ok, queue_b} = Forwarder.queue(forwarder, :b)
    {:ok, queue_c} = Forwarder.queue(forwarder, :c)
    {:ok, forwarder: forwarder, queue_a: queue_a, queue_b: queue_b,
          queue_c: queue_c}
  end

  test "it stops queues after stop", %{forwarder: forwarder,
                                       queue_a: queue_a, queue_b: queue_b,
                                       queue_c: queue_c} do
    ref_a = Process.monitor(queue_a)
    ref_b = Process.monitor(queue_b)
    ref_c = Process.monitor(queue_c)

    GenServer.stop(forwarder)

    assert_receive {:DOWN, ^ref_a, _, _, _}
    assert_receive {:DOWN, ^ref_b, _, _, _}
    assert_receive {:DOWN, ^ref_c, _, _, _}
  end

  describe "Nekto.Forwarder.forward_from/3" do
    test_with_mock "it forwards message from A", %{forwarder: forwarder},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      assert Forwarder.forward_from(forwarder, :a, "message") == :ok

      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert called Sender.send("PID#senderB", "message")
      assert called Sender.send("PID#senderC", "message")
    end

    test_with_mock "it forwards message from B", %{forwarder: forwarder},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      assert Forwarder.forward_from(forwarder, :b, "message") == :ok

      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert called Sender.send("PID#senderA", "message")
      assert called Sender.send("PID#senderC", "message")
    end

    test_with_mock "it puts message into A queue if A disconnected",
                   %{forwarder: forwarder, queue_a: queue_a, queue_c: queue_c},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      Forwarder.disconnect(forwarder, :a)
      assert Forwarder.forward_from(forwarder, :b, "message") == :ok

      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert !called Sender.send("PID#senderA", "message")
      assert called Sender.send("PID#senderC", "message")
      assert Queue.get_all(queue_a) == ["message"]
      assert Queue.get_all(queue_c) == []
    end

    test_with_mock "it puts message into B queue if B disconnected",
                   %{forwarder: forwarder, queue_b: queue_b, queue_c: queue_c},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      Forwarder.disconnect(forwarder, :b)
      assert Forwarder.forward_from(forwarder, :a, "message") == :ok

      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert !called Sender.send("PID#senderB", "message")
      assert called Sender.send("PID#senderC", "message")
      assert Queue.get_all(queue_b) == ["message"]
      assert Queue.get_all(queue_c) == []
    end

    test_with_mock "it ignores message A to B if A muted",
                   %{forwarder: forwarder, queue_a: queue_a, queue_c: queue_c},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      Forwarder.mute(forwarder, :a)
      assert Forwarder.forward_from(forwarder, :a, "message") == :ok

      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert !called Sender.send("PID#senderB", "message")
      assert !called Sender.send("PID#senderC", "message")
      assert Queue.get_all(queue_a) == []
      assert Queue.get_all(queue_c) == []
    end

    test_with_mock "it ignores message B to A if B muted",
                   %{forwarder: forwarder, queue_a: queue_a, queue_c: queue_c},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      Forwarder.mute(forwarder, :b)
      assert Forwarder.forward_from(forwarder, :b, "message") == :ok

      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert !called Sender.send("PID#senderA", "message")
      assert !called Sender.send("PID#senderC", "message")
      assert Queue.get_all(queue_a) == []
      assert Queue.get_all(queue_c) == []
    end
  end

  describe "Nekto.Forwarder.connect/2" do
    test "it marks client A as connected", %{forwarder: forwarder} do
      assert Forwarder.connect(forwarder, :a) == :ok
      assert Forwarder.connected?(forwarder, :a) == {:ok, true}
    end

    test "it marks client B as connected", %{forwarder: forwarder} do
      assert Forwarder.connect(forwarder, :b) == :ok
      assert Forwarder.connected?(forwarder, :b) == {:ok, true}
    end

    test_with_mock "it sends all queue to connected client A",
                   %{forwarder: forwarder, queue_a: queue},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      Forwarder.disconnect(forwarder, :a)

      # Fill queue
      Forwarder.forward_from(forwarder, :b, "message1")
      Forwarder.queue(forwarder, :a) # Waiting for end of async cast
      Forwarder.forward_from(forwarder, :b, "message2")
      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert Queue.get_all(queue) == ["message1", "message2"]

      assert Forwarder.connect(forwarder, :a) == :ok

      assert called Sender.send("PID#senderA", "message1")
      assert called Sender.send("PID#senderA", "message2")

      assert Queue.get_all(queue) == []
    end

    test_with_mock "it sends all queue to connected client B",
                   %{forwarder: forwarder, queue_b: queue},
                   Sender, [], [send: fn(_, _) -> :ok end] do
      Forwarder.disconnect(forwarder, :b)

      # Fill queue
      Forwarder.forward_from(forwarder, :a, "message1")
      Forwarder.queue(forwarder, :a) # Waiting for end of async cast
      Forwarder.forward_from(forwarder, :a, "message2")
      Forwarder.queue(forwarder, :a) # Waiting for end of async cast

      assert Queue.get_all(queue) == ["message1", "message2"]

      assert Forwarder.connect(forwarder, :b) == :ok

      assert called Sender.send("PID#senderB", "message1")
      assert called Sender.send("PID#senderB", "message2")

      assert Queue.get_all(queue) == []
    end

    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.connect(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.disconnect/2" do
    test "it marks client A as disconnected", %{forwarder: forwarder} do
      assert Forwarder.disconnect(forwarder, :a) == :ok
      assert Forwarder.connected?(forwarder, :a) == {:ok, false}
    end

    test "it marks client B as disconnected", %{forwarder: forwarder} do
      assert Forwarder.disconnect(forwarder, :b) == :ok
      assert Forwarder.connected?(forwarder, :b) == {:ok, false}
    end

    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.disconnect(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.mute/2" do
    test "it marks client A as muted", %{forwarder: forwarder} do
      assert Forwarder.mute(forwarder, :a) == :ok
      assert Forwarder.muted?(forwarder, :a) == {:ok, true}
    end

    test "it marks client B as muted", %{forwarder: forwarder} do
      assert Forwarder.mute(forwarder, :b) == :ok
      assert Forwarder.muted?(forwarder, :b) == {:ok, true}
    end

    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.mute(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.unmute/2" do
    test "it marks client A as unmuted", %{forwarder: forwarder} do
      assert Forwarder.unmute(forwarder, :a) == :ok
      assert Forwarder.muted?(forwarder, :a) == {:ok, false}
    end

    test "it marks client B as unmuted", %{forwarder: forwarder} do
      assert Forwarder.unmute(forwarder, :b) == :ok
      assert Forwarder.muted?(forwarder, :b) == {:ok, false}
    end

    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.unmute(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.connected?/2" do
    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.connected?(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.muted?/2" do
    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.muted?(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.queue/2" do
    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.queue(forwarder, :x) == :not_found
    end
  end

  describe "Nekto.Forwarder.deattach_client/2" do
    test "it deattaches client", %{forwarder: forwarder} do
      assert Forwarder.connected?(forwarder, :a) == {:ok, true}
      assert Forwarder.deattach_client(forwarder, :a) == :ok
      assert Forwarder.connected?(forwarder, :a) == :not_found
    end

    test "it stops client's queue", %{forwarder: forwarder, queue_a: queue} do
      ref = Process.monitor(queue)
      assert Forwarder.deattach_client(forwarder, :a) == :ok
      assert_receive {:DOWN, ^ref, _, _, _}
    end

    test "it returns :not_found if client doesn't registered",
         %{forwarder: forwarder} do
      assert Forwarder.deattach_client(forwarder, :x) == :not_found
    end
  end
end

defmodule Nekto.QueueTest do
  use ExUnit.Case, async: true

  alias Nekto.Queue

  setup do
    {:ok, queue} = Queue.start_link
    :ok = Queue.put(queue, 1)
    :ok = Queue.put(queue, 2)
    :ok = Queue.put(queue, 3)
    {:ok, queue: queue}
  end

  test "it stores putted values", %{queue: queue} do
    assert Queue.get_all(queue) == [1, 2, 3]
  end

  describe "Nekto.Queue.get/1" do
    test "it returns head element", %{queue: queue} do
      assert Queue.get(queue) == 1
      assert Queue.get_all(queue) == [1, 2, 3]
    end
  end

  describe "Nekto.Queue.pop/1" do
    test "it pops head element", %{queue: queue} do
      assert Queue.pop(queue) == 1
      assert Queue.get_all(queue) == [2, 3]
    end
  end

  describe "Nekto.Queue.pop_all/1" do
    test "it pops all elements", %{queue: queue} do
      assert Queue.pop_all(queue) == [1, 2, 3]
      assert Queue.get_all(queue) == []
    end
  end

  describe "Nekto.Queue.clear/1" do
    test "it clears queue", %{queue: queue} do
      assert Queue.clear(queue) == :ok
      assert Queue.get_all(queue) == []
    end
  end

  describe "Nekto.Queue.stop/1" do
    test "it stops queue", %{queue: queue} do
      ref = Process.monitor(queue)
      Queue.stop(queue)
      assert_receive {:DOWN, ^ref, _, _, _}
    end
  end
end

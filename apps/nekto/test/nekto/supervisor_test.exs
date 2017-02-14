defmodule Nekto.SupervisorTest do
  use ExUnit.Case, async: false

  import Mock
  alias Socket.Web
  alias NektoClient.Receiver
  alias Nekto.Supervisor
  alias Nekto.Forwarder
  alias Nekto.MessagesHandler

  setup do
    with_mock Web, [connect!: fn _ -> "socket" end] do
      {:ok, supervisor} = Supervisor.start_link("host.com")
      {:ok, supervisor: supervisor}
    end
  end

  describe "Nekto.Supervisor.start_link/1" do
    test "it adds MessagesHandler to receiver A",
         %{supervisor: supervisor} do
      gen_event = supervisor
                  |> Supervisor.client(:a)
                  |> NektoClient.Supervisor.receiver
                  |> Receiver.gen_event
      assert MessagesHandler in GenEvent.which_handlers(gen_event)
    end

    test "it adds MessagesHandler to receiver B",
         %{supervisor: supervisor} do
      gen_event = supervisor
                  |> Supervisor.client(:b)
                  |> NektoClient.Supervisor.receiver
                  |> Receiver.gen_event
      assert MessagesHandler in GenEvent.which_handlers(gen_event)
    end

    test "it attaches client A to forwarder", %{supervisor: supervisor} do
      forwarder = Supervisor.forwarder(supervisor)
      assert Forwarder.deattach_client(forwarder, :a) == :ok
    end

    test "it attaches client B to forwarder", %{supervisor: supervisor} do
      forwarder = Supervisor.forwarder(supervisor)
      assert Forwarder.deattach_client(forwarder, :b) == :ok
    end
  end

  describe "Nekto.Supervisor.start_link/2" do
    setup do
      with_mock Web, [connect!: fn(_, _) -> "socket" end] do
        {:ok, supervisor} = Supervisor.start_link("host.com",
                                                  path: '/websocket')
        {:ok, supervisor: supervisor}
      end
    end

    test "it adds MessagesHandler to receiver A",
         %{supervisor: supervisor} do
      gen_event = supervisor
                  |> Supervisor.client(:a)
                  |> NektoClient.Supervisor.receiver
                  |> Receiver.gen_event
      assert MessagesHandler in GenEvent.which_handlers(gen_event)
    end

    test "it adds MessagesHandler to receiver B",
         %{supervisor: supervisor} do
      gen_event = supervisor
                  |> Supervisor.client(:b)
                  |> NektoClient.Supervisor.receiver
                  |> Receiver.gen_event
      assert MessagesHandler in GenEvent.which_handlers(gen_event)
    end

    test "it attaches client A to forwarder", %{supervisor: supervisor} do
      forwarder = Supervisor.forwarder(supervisor)
      assert Forwarder.deattach_client(forwarder, :a) == :ok
    end

    test "it attaches client B to forwarder", %{supervisor: supervisor} do
      forwarder = Supervisor.forwarder(supervisor)
      assert Forwarder.deattach_client(forwarder, :b) == :ok
    end
  end

  describe "Nekto.Supervisor.stop/1" do
    test "it stops supervisor with normal reason", %{supervisor: supervisor} do
      ref = Process.monitor(supervisor)
      Supervisor.stop(supervisor)
      assert_receive {:DOWN, ^ref, _, _, :normal}
    end
  end

  describe "Nekto.Supervisor.stop/2" do
    test "it stops supervisor with reason", %{supervisor: supervisor} do
      ref = Process.monitor(supervisor)
      Supervisor.stop(supervisor, :normal)
      assert_receive {:DOWN, ^ref, _, _, :normal}
    end
  end

  describe "Nekto.Supervisor.client/2" do
    test "it returns supervisor of client A", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.client(:a)
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {:supervisor, NektoClient.Supervisor, 1}
    end

    test "it returns supervisor of client B", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.client(:b)
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {:supervisor, NektoClient.Supervisor, 1}
    end
  end

  describe "Nekto.Supervisor.sender/2" do
    test "it returns sender of client A", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.sender(:a)
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {NektoClient.Sender, :init, 1}
    end

    test "it returns supervisor of client B", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.sender(:b)
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {NektoClient.Sender, :init, 1}
    end
  end

  describe "Nekto.Supervisor.receiver/2" do
    test "it returns receiver of client A", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.receiver(:a)
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {NektoClient.Receiver, :init, 1}
    end

    test "it returns supervisor of client B", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.receiver(:b)
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {NektoClient.Receiver, :init, 1}
    end
  end

  describe "Nekto.Supervisor.forwarder/1" do
    test "it returns forwarder", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.forwarder
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {Nekto.Forwarder, :init, 1}
    end
  end
end

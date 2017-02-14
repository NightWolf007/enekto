defmodule NektoBot.ReceiverTest do
  use ExUnit.Case, async: false

  import Mock

  alias Nadia.Model.Update
  alias NektoBot.Receiver
  alias Support.Handler

  setup do
    {:ok, receiver} = Receiver.start_link
    {:ok, receiver: receiver}
  end

  describe "NektoBot.Receiver.add_handler/3" do
    test "it adds handler", %{receiver: receiver} do
      gen_event = Receiver.gen_event(receiver)
      Receiver.add_handler(receiver, Handler, [])

      GenEvent.notify(gen_event, {:test, "test"})
      assert GenEvent.call(gen_event, Handler, :messages) ==
        {:test, "test"}
    end
  end

  describe "NektoBot.Receiver.remove_handler/3" do
    test "it removes handler", %{receiver: receiver} do
      gen_event = Receiver.gen_event(receiver)
      Receiver.add_handler(receiver, Handler, [])
      Receiver.remove_handler(receiver, Handler, [])

      GenEvent.notify(gen_event, {:test, "test"})
      assert GenEvent.call(gen_event, Handler, :messages) ==
        {:error, :not_found}
    end
  end

  describe "NektoBot.Receiver.start_listening/1" do
    test "it starts listenning telegram messages", %{receiver: receiver} do
      Application.stop(:nekto_bot)
      update_id = 555_555_555
      message = %{test: "message"}
      updates = {:ok, [%Update{message: message, update_id: update_id}]}
      empty_updates = {:ok, []}
      with_mock(
        Nadia,
        [get_updates: fn(offset: offset, allowed_updates: ["message"]) ->
                        if (offset == 0), do: updates, else: empty_updates
                      end]
      ) do
        Receiver.start_listening(receiver)
        :timer.sleep(100)
        assert called Nadia.get_updates(offset: 0, allowed_updates: ["message"])
        assert called Nadia.get_updates(offset: update_id + 1,
                                        allowed_updates: ["message"])
      end
    end

    test "it handles errors", %{receiver: receiver} do
      Application.stop(:nekto_bot)
      with_mock Nadia, [get_updates: fn(_) -> {:error, "error"} end] do
        Receiver.start_listening(receiver)
        :timer.sleep(100)
        assert called Nadia.get_updates(offset: 0, allowed_updates: ["message"])
        assert called Nadia.get_updates(offset: 0, allowed_updates: ["message"])
      end
    end
  end
end

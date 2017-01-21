defmodule NektoClient.ReceiverTest do
  use ExUnit.Case, async: true

  alias NektoClient.Receiver
  alias Support.Handler

  setup do
    {:ok, receiver} = Receiver.start_link(nil)
    {:ok, receiver: receiver}
  end

  test "it adds handler", %{receiver: receiver} do
    gen_event = Receiver.gen_event(receiver)
    Receiver.add_handler(receiver, Handler, [])

    GenEvent.notify(gen_event, {:test, "test"})
    assert GenEvent.call(gen_event, Handler, :messages) ==
      {:test, "test"}
  end

  test "it removes handler", %{receiver: receiver} do
    gen_event = Receiver.gen_event(receiver)
    Receiver.add_handler(receiver, Handler, [])
    Receiver.remove_handler(receiver, Handler, [])

    GenEvent.notify(gen_event, {:test, "test"})
    assert GenEvent.call(gen_event, Handler, :messages) ==
      {:error, :not_found}
  end
end

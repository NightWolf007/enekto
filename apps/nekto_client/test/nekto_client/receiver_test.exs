defmodule NektoClient.ReceiverTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, receiver} = NektoClient.Receiver.start_link(nil)
    {:ok, receiver: receiver}
  end

  test "it adds handler", %{receiver: receiver} do
    gen_event = NektoClient.Receiver.gen_event(receiver)
    NektoClient.Receiver.add_handler(receiver, Support.Handler, [])

    GenEvent.notify(gen_event, {:test, "test"})
    assert GenEvent.call(gen_event, Support.Handler, :messages) ==
      {:test, "test"}
  end

  test "it removes handler", %{receiver: receiver} do
    gen_event = NektoClient.Receiver.gen_event(receiver)
    NektoClient.Receiver.add_handler(receiver, Support.Handler, [])
    NektoClient.Receiver.remove_handler(receiver, Support.Handler, [])

    GenEvent.notify(gen_event, {:test, "test"})
    assert GenEvent.call(gen_event, Support.Handler, :messages) ==
      {:error, :not_found}
  end
end

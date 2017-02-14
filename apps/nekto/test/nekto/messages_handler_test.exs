defmodule Nekto.MessagesHandlerTest do
  use ExUnit.Case, async: true

  import Mock

  alias NektoClient.Model.Message
  alias Nekto.Forwarder
  alias Nekto.MessagesHandler

  setup do
    {:ok, gen_event} = GenEvent.start_link
    :ok = GenEvent.add_handler(gen_event, MessagesHandler,
                               %{client: :a, forwarder: "PID#forwarder"})
    {:ok, gen_event: gen_event, forwarder: "PID#forwarder", client: :a}
  end

  describe "Nekto.MessagesHandler.handle_event(:chat_new_message)/1" do
    test_with_mock "it forwards message",
                   %{gen_event: ge, forwarder: forwarder, client: client},
                   Forwarder, [], [forward_from: fn(_, _, _) -> :ok end]  do
      message = %Message{text: "message"}
      :ok = GenEvent.notify(ge, {:chat_new_message, message})
      :ok = GenEvent.remove_handler(ge, MessagesHandler, []) # wait
      assert called Forwarder.forward_from(forwarder, client, "message")
    end
  end

  describe "Nekto.MessagesHandler.handle_event(:open_dialog)/1" do
    test_with_mock "it marks client as connected",
                   %{gen_event: ge, forwarder: forwarder, client: client},
                   Forwarder, [], [connect: fn(_, _) -> :ok end]  do
      :ok = GenEvent.notify(ge, {:open_dialog, "12345"})
      :ok = GenEvent.remove_handler(ge, MessagesHandler, []) # wait
      assert called Forwarder.connect(forwarder, client)
    end
  end

  describe "Nekto.MessagesHandler.handle_event(:close_dialog)/1" do
    test_with_mock "it marks client as disconnected",
                   %{gen_event: ge, forwarder: forwarder, client: client},
                   Forwarder, [], [disconnect: fn(_, _) -> :ok end]  do
      :ok = GenEvent.notify(ge, {:close_dialog, "12345"})
      :ok = GenEvent.remove_handler(ge, MessagesHandler, []) # wait
      assert called Forwarder.disconnect(forwarder, client)
    end
  end

  describe "Nekto.MessagesHandler.handle_event(:success_leave)/1" do
    test_with_mock "it marks client as disconnected",
                   %{gen_event: ge, forwarder: forwarder, client: client},
                   Forwarder, [], [disconnect: fn(_, _) -> :ok end]  do
      :ok = GenEvent.notify(ge, {:success_leave, "12345"})
      :ok = GenEvent.remove_handler(ge, MessagesHandler, []) # wait
      assert called Forwarder.disconnect(forwarder, client)
    end
  end
end

defmodule NektoBot.ForwarderTest do
  use ExUnit.Case, async: false

  import Mock

  alias NektoBot.Forwarder
  alias NektoClient.Model.Message

  setup do
    chat_id = 1000
    client = :a
    {:ok, gen_event} = GenEvent.start_link
    :ok = GenEvent.add_handler(gen_event, Forwarder,
                               %{chat_id: chat_id, client: client})
    {:ok, gen_event: gen_event, chat_id: chat_id}
  end

  describe "Nekto.Forwarder.handle_event(:chat_new_message)/1" do
    test "it sends message to telegram",
         %{gen_event: ge, chat_id: chat_id} do
      message = %Message{text: "hello"}
      with_mock Nadia, [send_message: fn(_, _) -> :ok end] do
        :ok = GenEvent.notify(ge, {:chat_new_message, message})
        :ok = GenEvent.remove_handler(ge, Forwarder, []) # wait
        assert called Nadia.send_message(chat_id, "A -> hello")
      end
    end
  end

  describe "Nekto.Forwarder.handle_event(:open_dialog)/1" do
    test "it sends message to telegram",
         %{gen_event: ge, chat_id: chat_id} do
      with_mock Nadia, [send_message: fn(_, _) -> :ok end] do
        :ok = GenEvent.notify(ge, {:open_dialog, "dialog"})
        :ok = GenEvent.remove_handler(ge, Forwarder, []) # wait
        assert called Nadia.send_message(chat_id, "Client A found.")
      end
    end
  end

  describe "Nekto.Forwarder.handle_event(:close_dialog)/1" do
    test "it sends message to telegram",
         %{gen_event: ge, chat_id: chat_id} do
      with_mock Nadia, [send_message: fn(_, _) -> :ok end] do
        :ok = GenEvent.notify(ge, {:close_dialog, "dialog"})
        :ok = GenEvent.remove_handler(ge, Forwarder, []) # wait
        assert called Nadia.send_message(chat_id, "Client A closed dialog.")
      end
    end
  end
end

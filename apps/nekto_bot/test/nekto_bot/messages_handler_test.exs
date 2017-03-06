defmodule NektoBot.MessagesHandlerTest do
  use ExUnit.Case, async: true

  import Mock

  alias NektoBot.MessagesHandler
  alias NektoBot.Controller

  setup do
    {:ok, gen_event} = GenEvent.start_link
    :ok = GenEvent.add_handler(gen_event, MessagesHandler,
                               %{controller: "PID#controller", chats: %{}})
    {:ok, gen_event: gen_event, controller: "PID#controller"}
  end

  describe "Nekto.MessagesHandler.handle_event(:message)/1" do
    test "it sends parsed message to controller",
         %{gen_event: ge, controller: controller} do
      message = %{text: "/send A hello", chat: %{id: 12345}}
      with_mock Controller, [exec: fn(_, _, _) -> :ok end] do
        :ok = GenEvent.notify(ge, {:message, message})
        :ok = GenEvent.remove_handler(ge, MessagesHandler, []) # wait
        assert called Controller.exec(controller, {:send, :a, "hello"}, message)
      end
    end

    test "it sends unknown_command to controller",
         %{gen_event: ge, controller: controller} do
      message = %{text: "/unknown A B", chat: %{id: 12345}}
      with_mock Controller, [unknown_command: fn(_, _) -> :ok end] do
        :ok = GenEvent.notify(ge, {:message, message})
        :ok = GenEvent.remove_handler(ge, MessagesHandler, []) # wait
        assert called Controller.unknown_command(controller, message)
      end
    end
  end
end

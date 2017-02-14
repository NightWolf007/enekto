defmodule NektoBot.ControllerTest do
  use ExUnit.Case, async: false

  import Mock

  alias NektoBot.Controller
  alias NektoBot.Forwarder

  setup do
    Application.stop(:nekto_bot)
    {:ok, controller} = Controller.start_link
    {:ok, controller: controller, chat_id: 12345, nekto: "PID#nekto"}
  end

  describe "NektoBot.Controller.unknown_command/2" do
    test "it sends error message to telegram",
         %{controller: controller, chat_id: chat_id} do
      with_mock Nadia, [send_message: fn(_, _) -> :ok end] do
        Controller.unknown_command(controller, %{chat: %{id: chat_id}})
        assert called Nadia.send_message(chat_id, "Error! Unknown command")
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :connect" do
    test "it prepares connection and sends success message",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :reconnect" do
    test "it stops and prepares connection and sends success message",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           stop: fn _ -> :ok end,
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        :ok = Controller.exec(controller, {:reconnect}, %{chat: %{id: chat_id}})
        assert called Nekto.stop(nekto)
        assert called Nadia.send_message(chat_id, "Connection closed.")

        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")
      end
    end

    test "it also prepares connection when chat_id not found",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:reconnect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :set" do
    test "it sends success message to telegram",
         %{controller: controller, chat_id: chat_id} do
      with_mock Nadia, [send_message: fn(_, _) -> :ok end] do
        :ok = Controller.exec(controller, {:set, :a, %{sex: "M"}},
                              %{chat: %{id: chat_id}})
        assert called Nadia.send_message(chat_id,
                                         "Client A setted as %{sex: \"M\"}.")
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :search client" do
    test "it searches client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           search: fn(_, _, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        params = %{sex: "M"}
        :ok = Controller.exec(controller, {:set, :a, params},
                              %{chat: %{id: chat_id}})
        assert called Nadia.send_message(chat_id,
                                         "Client A setted as %{sex: \"M\"}.")

        :ok = Controller.exec(controller, {:search, :a},
                              %{chat: %{id: chat_id}})
        assert called Nekto.search(nekto, :a, params)
        assert called Nadia.send_message(chat_id, "Searching client A...")
      end
    end

    test "it sends not setted error message with not setted params",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           search: fn(_, _, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        params = %{sex: "M"}

        :error = Controller.exec(controller, {:search, :a},
                                 %{chat: %{id: chat_id}})
        refute called Nekto.search(nekto, :a, params)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't setted. " <>
          "Please, set client and try again."
        )
      end
    end

    test "it sends not connected error message with not connected client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [search: fn(_, _, _) -> :ok end]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        params = %{sex: "M"}
        :error = Controller.exec(controller, {:search, :a},
                                 %{chat: %{id: chat_id}})
        refute called Nekto.search(nekto, :a, params)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't connected. " <>
          "Please, connect and try again."
        )
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :search" do
    test "it searches clients",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           search: fn(_, _, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        params_a = %{sex: "M"}
        params_b = %{sex: "W"}

        :ok = Controller.exec(controller, {:set, :a, params_a},
                              %{chat: %{id: chat_id}})
        assert called Nadia.send_message(chat_id,
                                         "Client A setted as %{sex: \"M\"}.")

        :ok = Controller.exec(controller, {:set, :b, params_b},
                              %{chat: %{id: chat_id}})
        assert called Nadia.send_message(chat_id,
                                         "Client B setted as %{sex: \"W\"}.")

        :ok = Controller.exec(controller, {:search}, %{chat: %{id: chat_id}})
        assert called Nekto.search(nekto, :a, params_a)
        assert called Nekto.search(nekto, :b, params_b)
        assert called Nadia.send_message(chat_id, "Searching client A...")
        assert called Nadia.send_message(chat_id, "Searching client B...")
      end
    end

    test "it sends not setted error message with not setted params",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           search: fn(_, _, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        params_a = %{sex: "M"}
        params_b = %{sex: "W"}

        :error = Controller.exec(controller, {:search}, %{chat: %{id: chat_id}})
        refute called Nekto.search(nekto, :a, params_a)
        refute called Nekto.search(nekto, :b, params_b)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't setted. " <>
          "Please, set client and try again."
        )
        assert called Nadia.send_message(
          chat_id,
          "Error! Client B haven't setted. " <>
          "Please, set client and try again."
        )
      end
    end

    test "it sends not connected error message with not connected client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [search: fn(_, _, _) -> :ok end]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        params_a = %{sex: "M"}
        params_b = %{sex: "W"}
        :error = Controller.exec(controller, {:search}, %{chat: %{id: chat_id}})
        refute called Nekto.search(nekto, :a, params_a)
        refute called Nekto.search(nekto, :b, params_b)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't connected. " <>
          "Please, connect and try again."
        )
        assert called Nadia.send_message(
          chat_id,
          "Error! Client B haven't connected. " <>
          "Please, connect and try again."
        )
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :send client" do
    test "it sends message to client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           connected?: fn(_, _) -> {:ok, true} end,
           send: fn(_, _, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        :ok = Controller.exec(controller, {:send, :a, "message"},
                              %{chat: %{id: chat_id}})
        assert called Nekto.connected?(nekto, :a)
        assert called Nekto.send(nekto, :a, "message")
        assert called Nadia.send_message(chat_id, "YOU => A -> message")
      end
    end

    test "it sends not found error message with not founded client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           connected?: fn(_, _) -> {:ok, false} end,
           send: fn(_, _, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        :error = Controller.exec(controller, {:send, :a, "message"},
                                 %{chat: %{id: chat_id}})
        assert called Nekto.connected?(nekto, :a)
        refute called Nekto.send(nekto, :a, "message")
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't found yet. " <>
          "Please, search it or wait."
        )
      end
    end

    test "it sends not connected error message with not connected client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [send: fn(_, _, _) -> :ok end]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :error = Controller.exec(controller, {:send, :a, "message"},
                                 %{chat: %{id: chat_id}})
        refute called Nekto.send(nekto, :a, "message")
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't connected. " <>
          "Please, connect and try again."
        )
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :mute client" do
    test "it mutes client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           mute: fn(_, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        :ok = Controller.exec(controller, {:mute, :a}, %{chat: %{id: chat_id}})
        assert called Nekto.mute(nekto, :a)
        assert called Nadia.send_message(chat_id, "Client A muted.")
      end
    end

    test "it sends not connected error message with not connected client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [mute: fn(_, _) -> :ok end]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :error = Controller.exec(controller, {:mute, :a},
                                 %{chat: %{id: chat_id}})
        refute called Nekto.mute(nekto, :a)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't connected. " <>
          "Please, connect and try again."
        )
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :unmute client" do
    test "it unmutes client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           unmute: fn(_, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        :ok = Controller.exec(controller, {:unmute, :a},
                              %{chat: %{id: chat_id}})
        assert called Nekto.unmute(nekto, :a)
        assert called Nadia.send_message(chat_id, "Client A unmuted.")
      end
    end

    test "it sends not connected error message with not connected client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [unmute: fn(_, _) -> :ok end]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :error = Controller.exec(controller, {:unmute, :a},
                                 %{chat: %{id: chat_id}})
        refute called Nekto.unmute(nekto, :a)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't connected. " <>
          "Please, connect and try again."
        )
      end
    end
  end

  describe "NektoBot.Controller.exec/3 :kick client" do
    test "it searches client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [
           start: fn -> {:ok, nekto} end,
           add_handler: fn(_, _, _, _) -> :ok end,
           start_listening: fn(_) -> :ok end,
           authenticate: fn(_) -> :ok end,
           kick: fn(_, _) -> :ok end
         ]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :ok = Controller.exec(controller, {:connect}, %{chat: %{id: chat_id}})
        assert called Nekto.add_handler(nekto, :a, Forwarder,
                                        %{chat_id: chat_id, client: :a})
        assert called Nekto.add_handler(nekto, :b, Forwarder,
                                        %{chat_id: chat_id, client: :b})
        assert called Nekto.start_listening(nekto)
        assert called Nekto.authenticate(nekto)
        assert called Nadia.send_message(chat_id, "Successfully connected!")

        :ok = Controller.exec(controller, {:kick, :a}, %{chat: %{id: chat_id}})
        assert called Nekto.kick(nekto, :a)
        assert called Nadia.send_message(chat_id, "Client A kicked.")
      end
    end

    test "it sends not connected error message with not connected client",
         %{controller: controller, chat_id: chat_id, nekto: nekto} do
      with_mocks([
        {Nekto, [], [kick: fn(_, _) -> :ok end]},
        {Nadia, [], [send_message: fn(_, _) -> :ok end]}
      ]) do
        :error = Controller.exec(controller, {:kick, :a},
                                 %{chat: %{id: chat_id}})
        refute called Nekto.kick(nekto, :a)
        assert called Nadia.send_message(
          chat_id,
          "Error! Client A haven't connected. " <>
          "Please, connect and try again."
        )
      end
    end
  end
end

defmodule NektoBot.MessagesHandler do
  @moduledoc """
  GenEvent Telegram messages handler
  """

  use GenEvent
  alias NektoBot.Command
  alias NektoBot.Controller
  alias NektoBot.InputFsm
  alias NektoBot.SetupSender

  @doc """
  Receives messages from telegram, parse them and sends to controller
  """
  def handle_event({:message, message},
                   %{controller: controller, chats: chats}) do
    chat_id = chat_id(message)
    fsm = Map.get(chats, chat_id) || InputFsm.new
    case fsm.state do
      :command_input ->
        case parse_message(message) do
          {:ok, {:set, client}} ->
            params = Controller.setup(controller, nil, client, fsm.state,
                                      message)
            fsm = fsm |> InputFsm.setup(client)
            send_state(fsm.state, chat_id, client, params)
          {:ok, command} ->
            controller |> Controller.exec(command, message)
          {:error, :unknown_command} ->
            controller |> Controller.unknown_command(message)
        end
      state when state in [:my_sex_input, :wish_sex_input] ->
        input = parse_sex(message)
        params = Controller.setup(controller, input, fsm.data, fsm.state,
                                  message)
        fsm = fsm |> InputFsm.entered(input)
        send_state(fsm.state, chat_id, fsm.data, params)
      :my_age_input ->
        input = parse_my_age(message)
        params = if is_nil(input) do
                   Controller.settings(controller, chat_id, fsm.data)
                 else
                   Controller.setup(controller, input, fsm.data, fsm.state,
                                    message)
                 end
        fsm = fsm |> InputFsm.entered(input)
        send_state(fsm.state, chat_id, fsm.data, params)
      :wish_age_input ->
        input = parse_wish_age(message) ||
                ["0t17", "18t21", "22t25", "25t35", "36t100"]
        params = Controller.setup(controller, input, fsm.data, fsm.state,
                                  message)
        fsm = fsm |> InputFsm.entered(input)
        send_state(fsm.state, chat_id, fsm.data, params)
    end
    {:ok, %{controller: controller, chats: Map.put(chats, chat_id, fsm)}}
  end

  def handle_event(_, state) do
    {:ok, state}
  end


  defp send_state(state, chat_id, client, params) do
    case state do
      :command_input ->
        SetupSender.command_input(chat_id, client, params)
      :my_sex_input ->
        SetupSender.my_sex_input(chat_id, client)
      :wish_sex_input ->
        SetupSender.wish_sex_input(chat_id, client)
      :my_age_input ->
        SetupSender.my_age_input(chat_id, client)
      :wish_age_input ->
        SetupSender.wish_age_input(chat_id, client)
    end
  end

  defp parse_message(message) do
    message
    |> Map.get(:text)
    |> Command.parse
  end

  defp parse_sex(message) do
    case Map.get(message, :text) do
      "M" -> "M"
      "F" -> "F"
      _ -> nil
    end
  end

  defp parse_my_age(message) do
    case Map.get(message, :text) do
      "0 - 17" -> {0, 17}
      "18 - 21" -> {18, 21}
      "22 - 25" -> {22, 25}
      "25 - 35" -> {25, 35}
      "36 - 100" -> {36, 100}
      _ -> nil
    end
  end

  defp parse_wish_age(message) do
    case Map.get(message, :text) do
      "0 - 17" -> "0t17"
      "18 - 21" -> "18t21"
      "22 - 25" -> "22t25"
      "25 - 35" -> "25t35"
      "36 - 100" -> "36t100"
      _ -> nil
    end
  end

  defp chat_id(message) do
    message
    |> Map.get(:chat)
    |> Map.get(:id)
  end
end

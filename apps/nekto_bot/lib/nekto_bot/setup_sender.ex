defmodule NektoBot.SetupSender do
  @moduledoc """
  Sends messages with ketboard to telegram
  """

  def command_input(chat_id, client, params) do
    Nadia.send_message(
      chat_id,
      "Client #{client_name(client)} setted as #{inspect(params)}.",
      reply_markup: %Nadia.Model.ReplyKeyboardHide{hide_keyboard: true}
    )
  end

  def my_sex_input(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Choose your sex for client #{client_name(client)}.",
      reply_markup: sex_input_keyboard
    )
  end

  def wish_sex_input(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Choose wish sex for client #{client_name(client)}.",
      reply_markup: sex_input_keyboard
    )
  end

  def my_age_input(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Choose your age for client #{client_name(client)}.",
      reply_markup: age_input_keyboard
    )
  end

  def wish_age_input(chat_id, client) do
    Nadia.send_message(
      chat_id,
      "Choose wish age for client #{client_name(client)}.",
      reply_markup: age_input_keyboard
    )
  end


  defp sex_input_keyboard do
    %Nadia.Model.ReplyKeyboardMarkup{
      keyboard: [
        [%Nadia.Model.KeyboardButton{text: "-"},
         %Nadia.Model.KeyboardButton{text: "M"},
         %Nadia.Model.KeyboardButton{text: "F"}]
      ]
    }
  end

  defp age_input_keyboard do
    %Nadia.Model.ReplyKeyboardMarkup{
      keyboard: [
        [%Nadia.Model.KeyboardButton{text: "-"}],
        [%Nadia.Model.KeyboardButton{text: "0 - 17"}],
        [%Nadia.Model.KeyboardButton{text: "18 - 21"}],
        [%Nadia.Model.KeyboardButton{text: "22 - 25"}],
        [%Nadia.Model.KeyboardButton{text: "25 - 35"}],
        [%Nadia.Model.KeyboardButton{text: "36 - 100"}]
      ]
    }
  end

  defp client_name(client) do
    client
    |> Atom.to_string
    |> String.upcase
  end
end

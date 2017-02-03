defmodule NektoBot.TelegramHandler do
  @moduledoc """
  GenEvent Telegram messages handler
  """

  use GenEvent
  alias NektoBot.Command
  alias NektoBot.Controller

  @doc """
  Receives success_auth message and sets user in NektoClient.Sender
  """
  def handle_event({:message, message}, state) do
    controller = state |> Map.get(:controller)
    case parse_message(message) do
      {:ok, command} ->
        controller |> Controller.exec(command, message)
      {:error, :unknown_command} ->
        controller |> Controller.unknown_command(message)
    end
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  defp parse_message(message) do
    message
    |> Map.get(:text)
    |> Command.parse
  end
end

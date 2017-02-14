defmodule NektoBot.MessagesHandler do
  @moduledoc """
  GenEvent Telegram messages handler
  """

  use GenEvent
  alias NektoBot.Command
  alias NektoBot.Controller

  @doc """
  Receives messages from telegram, parse them and sends to controller
  """
  def handle_event({:message, message}, %{controller: controller} = state) do
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

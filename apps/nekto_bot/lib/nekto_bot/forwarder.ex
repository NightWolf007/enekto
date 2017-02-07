defmodule NektoBot.Forwarder do
  @moduledoc """
  GenEvent handler for forwarding messages to telegram
  """

  use GenEvent

  @doc """
  Receives open_dialog message and forwards it to telegram
  """
  def handle_event({:chat_new_message, message}, state) do
    state
    |> Map.get(:chat_id)
    |> Nadia.send_message(format_message(Map.get(state, :client), message.text))
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  defp format_message(client, message) do
    "#{client} -> #{message}"
  end
end

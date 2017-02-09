defmodule NektoBot.Forwarder do
  @moduledoc """
  GenEvent handler for forwarding messages to telegram
  """

  use GenEvent

  @doc """
  Receives new message and forwards it to telegram
  """
  def handle_event({:chat_new_message, message}, state) do
    state
    |> Map.get(:chat_id)
    |> Nadia.send_message(format_message(Map.get(state, :client), message.text))
    {:ok, state}
  end

  @doc """
  Receives search result and forwards it to telegram
  """
  def handle_event({:open_dialog, _dialog}, state) do
    state
    |> Map.get(:chat_id)
    |> Nadia.send_message("Client #{Map.get(state, :client)} founded.")
    {:ok, state}
  end

  @doc """
  Receives message about closed dialog
  """
  def handle_event({:close_dialog, _dialog}, state) do
    state
    |> Map.get(:chat_id)
    |> Nadia.send_message("Client #{Map.get(state, :client)} closed dialog.")
    {:ok, state}
  end

  def handle_event(m, state) do
    IO.puts inspect(m)
    IO.puts inspect(state)
    {:ok, state}
  end

  defp format_message(client, message) do
    "#{client} -> #{message}"
  end
end

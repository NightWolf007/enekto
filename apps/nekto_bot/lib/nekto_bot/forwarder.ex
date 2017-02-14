defmodule NektoBot.Forwarder do
  @moduledoc """
  GenEvent handler for forwarding messages to telegram
  """

  use GenEvent

  @doc """
  Receives new message and forwards it to telegram
  """
  def handle_event({:chat_new_message, message},
                   %{chat_id: chat_id, client: client} = state) do
    Nadia.send_message(chat_id, format_message(client, message.text))
    {:ok, state}
  end

  @doc """
  Receives search result and forwards it to telegram
  """
  def handle_event({:open_dialog, _dialog},
                   %{chat_id: chat_id, client: client} = state) do
    Nadia.send_message(
      chat_id,
      "Client #{format_client(client)} found."
    )
    {:ok, state}
  end

  @doc """
  Receives message about closed dialog
  """
  def handle_event({:close_dialog, _dialog},
                   %{chat_id: chat_id, client: client} = state) do
    Nadia.send_message(
      chat_id,
      "Client #{format_client(client)} closed dialog."
    )
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  defp format_client(client) do
    client
    |> Atom.to_string
    |> String.upcase
  end

  defp format_message(client, message) do
    "#{format_client(client)} -> #{message}"
  end
end

defmodule Nekto.MessagesHandler do
  @moduledoc """
  GenEvent handler for forwarding messages
  """

  use GenEvent
  alias Nekto.Forwarder

  @doc """
  Receives new message and forwards it to sender
  """
  def handle_event({:chat_new_message, message},
                   %{client: client, forwarder: forwarder} = state) do
    forwarder
    |> Forwarder.forward_from(client, message.text)
    {:ok, state}
  end

  @doc """
  Receives search result
  """
  def handle_event({:open_dialog, _dialog},
                   %{client: client, forwarder: forwarder} = state) do
    forwarder
    |> Forwarder.connect(client)
    {:ok, state}
  end

  @doc """
  Receives closed_dialog message
  """
  def handle_event({:close_dialog, _dialog},
                   %{client: client, forwarder: forwarder} = state) do
    forwarder
    |> Forwarder.disconnect(client)
    {:ok, state}
  end

  @doc """
  Receives success_leave message
  """
  def handle_event({:success_leave, _dialog},
                   %{client: client, forwarder: forwarder} = state) do
    forwarder
    |> Forwarder.disconnect(client)
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end
end

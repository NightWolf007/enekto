defmodule Nekto.Forwarder do
  @moduledoc """
  GenEvent handler for forwarding messages
  """

  use GenEvent
  alias NektoClient.Sender

  @doc """
  Receives new message and forwards it to sender
  """
  def handle_event({:chat_new_message, message}, sender) do
    Sender.send(sender, message.text)
    {:ok, sender}
  end

  def handle_event(_, sender) do
    {:ok, sender}
  end
end

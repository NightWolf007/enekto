defmodule Nekto.Forwarder do
  @moduledoc """
  GenEvent handler for forwarding messages
  """

  use GenEvent
  alias NektoClient.Sender
  alias Nekto.ForwardingController

  @doc """
  Receives new message and forwards it to sender
  """
  def handle_event({:chat_new_message, message},
                   %{client: client, forwarding_controller: controller,
                     sender: sender, buffer: buffer} = state) do
    case ForwardingController.forward_from?(controller, client) do
      true ->
        Sender.send(sender, message.text)
        {:ok, state}
      false ->
        {:ok, Map.merge(state, %{buffer: [buffer | message.text]})}
    end
  end

  def handle_event(_, state) do
    {:ok, state}
  end
end

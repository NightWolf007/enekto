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
      false ->
        if !ForwardingController.muted?(controller, client) do
          Agent.update(buffer, fn(list) -> [list | message.text] end)
        end
    end
    {:ok, state}
  end

  @doc """
  Receives search result and forwards it to telegram
  """
  def handle_event({:open_dialog, _dialog},
                   %{client: client, forwarding_controller: controller,
                     sender: sender, buffer: buffer} = state) do
    ForwardingController.connect(controller, client)
    buffer
    |> Agent.get(fn(list) -> list end)
    |> Enum.each(fn(m) -> Sender.send(sender, m) end)
    Agent.update(buffer, fn(_) -> [] end)
    {:ok, state}
  end

  @doc """
  Receives message about closed dialog
  """
  def handle_event({:close_dialog, _dialog},
                   %{client: client,
                     forwarding_controller: controller} = state) do
    ForwardingController.disconnect(controller, client)
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end
end

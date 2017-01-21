defmodule NektoClient.Handler do
  @moduledoc """
  GenEvent handler for setup Sender
  """

  use GenEvent
  alias NektoClient.Sender

  @doc """
  Receives success_auth message and sets user in NektoClient.Sender
  """
  def handle_event({:success_auth, user}, sender) do
    Sender.set_user(sender, user)
    {:ok, sender}
  end

  @doc """
  Receives open_dialog message and sets dialog in NektoClient.Sender
  """
  def handle_event({:open_dialog, dialog}, sender) do
    Sender.set_dialog(sender, dialog)
    {:ok, sender}
  end

  def handle_event(_, sender) do
    {:ok, sender}
  end
end

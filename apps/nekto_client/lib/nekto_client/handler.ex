defmodule NektoClient.Handler do
  use GenEvent

  @doc """
  Receives success_auth message and sets user in NektoClient.Sender
  """
  def handle_event({:success_auth, user}, sender) do
    NektoClient.Sender.set_user(sender, user)
    {:ok, sender}
  end

  @doc """
  Receives open_dialog message and sets dialog in NektoClient.Sender
  """
  def handle_event({:open_dialog, dialog}, sender) do
    NektoClient.Sender.set_dialog(sender, dialog)
    {:ok, sender}
  end

  def handle_event(_, sender) do
    {:ok, sender}
  end
end

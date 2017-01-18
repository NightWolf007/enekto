defmodule NektoClient.Handler do
  use GenEvent

  def handle_event({:success_auth, user}, sender) do
    NektoClient.Sender.set_user(sender, user)
    {:ok, sender}
  end

  def handle_event({:open_dialog, dialog}, sender) do
    NektoClient.Sender.set_dialog(sender, dialog)
    {:ok, sender}
  end

  def handle_event(_, sender) do
    {:ok, sender}
  end
end

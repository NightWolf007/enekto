defmodule NektoClient.Model.Message do
  defstruct [:id, :dialog_id, :uid, :text]

  def new(id, dialog_id, uid, text) do
    %NektoClient.Model.Message{
      id: id, dialog_id: dialog_id, uid: uid, text: text
    }
  end
end

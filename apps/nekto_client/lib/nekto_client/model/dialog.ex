defmodule NektoClient.Model.Dialog do
  defstruct id: nil, uids: []

  def new(id, uids) do
    %NektoClient.Model.Dialog{id: id, uids: uids}
  end
end

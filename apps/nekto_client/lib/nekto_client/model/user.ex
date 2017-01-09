defmodule NektoClient.Model.User do
  defstruct [:id]

  def new(id) do
    %NektoClient.Model.User{id: id}
  end
end

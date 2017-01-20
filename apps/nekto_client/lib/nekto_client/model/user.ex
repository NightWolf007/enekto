defmodule NektoClient.Model.User do
  defstruct [:id]

  @doc """
  Creates new user struct

  ## Examples

      iex> NektoClient.Model.User.new(12345)
      %NektoClient.Model.User{id: 12345}
  """
  def new(id) do
    %NektoClient.Model.User{id: id}
  end
end

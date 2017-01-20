defmodule NektoClient.Model.Search do
  defstruct my_sex: nil, wish_sex: nil,
            my_age_from: nil, my_age_to: nil, wish_age: []

  @doc """
  Formats search struct for sending

  ## Examples

      iex> search = %NektoClient.Model.Search{my_sex: "M", wish_sex: "F",
      ...>                                    my_age_from: 18, my_age_to: 21,
      ...>                                    wish_age: ["18t21"]}
      iex> NektoClient.Model.Search.format(search)
      %NektoClient.Model.Search{my_sex: "M", wish_sex: "F",
                                my_age_from: "18", my_age_to: "21",
                                wish_age: ["18t21"]}
  """
  def format(search) do
    %NektoClient.Model.Search{
      my_sex: to_string(search.my_sex),
      wish_sex: to_string(search.wish_sex),
      my_age_from: to_string(search.my_age_from),
      my_age_to: to_string(search.my_age_to),
      wish_age: search.wish_age
    }
  end
end

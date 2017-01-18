defmodule NektoClient.Model.Search do
  defstruct my_sex: nil, wish_sex: nil,
            my_age_from: nil, my_age_to: nil, wish_age: []

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

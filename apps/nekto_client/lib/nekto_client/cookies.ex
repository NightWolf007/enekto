defmodule NektoClient.Cookies do
  def parse(cookies) do
    cookies
    |> String.split("; ")
    |> Enum.map(fn(x) -> x |> String.split("=") |> List.to_tuple end)
  end
end

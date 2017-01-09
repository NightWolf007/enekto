defmodule NektoClient.HTTPClient do
  def head! do
    HTTPoison.head! "http://nekto.me/chat/"
  end

  def chat_token! do
    head!.headers
    |> NektoClient.Headers.find("Set-Cookie")
    |> Enum.join("; ")
    |> NektoClient.Cookies.parse
    |> List.keyfind("chat_token", 0)
    |> elem(1)
  end
end

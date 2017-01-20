defmodule NektoClient.HTTPClientTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open
    {:ok, bypass: bypass}
  end

  test "it returns chat token", %{bypass: bypass} do
    Bypass.expect bypass, fn conn ->
      assert "/chat" == conn.request_path
      assert "HEAD" == conn.method
      conn
      |> Plug.Conn.put_resp_header("Content-Type", "text/html; charset=utf-8")
      |> Plug.Conn.put_resp_header(
           "Set-Cookie",
           "__cfduid=dfb9f97c61d1cd817536988f688e12b0f1484933721; " <>
           "expires=Sat, 20-Jan-18 17:35:21 GMT; " <>
           "path=/; domain=.nekto.me; HttpOnly"
      )
      |> Plug.Conn.put_resp_header(
           "Set-Cookie",
           "chat_token=d13ca8fa-df36-11e6-8195-a4b1db396c9f; " <>
           "expires=Mon, 18-Jan-2027 17:35:21 GMT; path=/"
      )
      |> Plug.Conn.resp(200, "")
    end
    assert NektoClient.HTTPClient.chat_token!(endpoint_url(bypass.port)) ==
      "d13ca8fa-df36-11e6-8195-a4b1db396c9f"
  end

  defp endpoint_url(port) do
    "http://localhost:#{port}"
  end
end

defmodule NektoClient.Handler do
  use GenEvent

  def handle_event({"success_auth", user}) do
    IO.puts "User: #{inspect user}"
  end

  def handle_event({notice, message}) do
    IO.puts "#{notice}: #{message}"
  end
end

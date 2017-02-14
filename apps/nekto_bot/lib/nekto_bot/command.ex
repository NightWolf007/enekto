defmodule NektoBot.Command do
  @moduledoc """
  Module for parsing Telegram commands
  """

  @doc """
  Parses the given message into a command

  ## Examples

      iex> NektoBot.Command.parse "/set A sex: M, age_from: 18"
      {:ok, {:set, :a, %{"sex" => "M", "age_from" => "18"}}}
      iex> NektoBot.Command.parse("/set B sex: W, age_from: 18, age_to: 21, " <>
      ...>                        "wish_age: [18t21]")
      {:ok, {:set, :b, %{"sex" => "W", "age_from" => "18", "age_to" => "21",
                         "wish_age" => ["18t21"]}}}
      iex> NektoBot.Command.parse("/set B sex:M  ,age_from: 18,    age_to: 21," <>
      ...>                        "    , wish_age: [18t21-22t25]")
      {:ok, {:set, :b, %{"sex" => "M", "age_from" => "18", "age_to" => "21",
                         "wish_age" => ["18t21", "22t25"]}}}
      iex> NektoBot.Command.parse "/search"
      {:ok, {:search}}
      iex> NektoBot.Command.parse "/search A"
      {:ok, {:search, :a}}
      iex> NektoBot.Command.parse "/search B"
      {:ok, {:search, :b}}
      iex> NektoBot.Command.parse "/kick A"
      {:ok, {:kick, :a}}
      iex> NektoBot.Command.parse "/kick B"
      {:ok, {:kick, :b}}
      iex> NektoBot.Command.parse "/mute A"
      {:ok, {:mute, :a}}
      iex> NektoBot.Command.parse "/mute B"
      {:ok, {:mute, :b}}
      iex> NektoBot.Command.parse "/send A Hello!"
      {:ok, {:send, :a, "Hello!"}}
      iex> NektoBot.Command.parse "/send B Hello!"
      {:ok, {:send, :b, "Hello!"}}
      iex> NektoBot.Command.parse "/connect"
      {:ok, {:connect}}
      iex> NektoBot.Command.parse "/reconnect"
      {:ok, {:reconnect}}

  Unknown commands or commands with the wrong number of
  arguments return an error:

      iex> NektoBot.Command.parse "/unknown A B"
      {:error, :unknown_command}
      iex> NektoBot.Command.parse "/set A"
      {:error, :unknown_command}
      iex> NektoBot.Command.parse "/kick"
      {:error, :unknown_command}
      iex> NektoBot.Command.parse "/send B"
      {:error, :unknown_command}
  """
  def parse(message) do
    case String.split(message) do
      ["/set", client | attrs] when client in ["A", "B"] and attrs != [] ->
        {:ok, {:set, parse_client(client), attrs
                                           |> Enum.join
                                           |> parse_attributes
                                           |> parse_wish_age}}
      ["/search"] ->
        {:ok, {:search}}
      ["/search", client] when client in ["A", "B"] ->
        {:ok, {:search, parse_client(client)}}
      ["/kick", client] when client in ["A", "B"] ->
        {:ok, {:kick, parse_client(client)}}
      ["/mute", client] when client in ["A", "B"] ->
        {:ok, {:mute, parse_client(client)}}
      ["/unmute", client] when client in ["A", "B"] ->
        {:ok, {:unmute, parse_client(client)}}
      ["/send", client | text] when client in ["A", "B"] and text != [] ->
        {:ok, {:send, parse_client(client), Enum.join(text, " ")}}
      ["/connect"] ->
        {:ok, {:connect}}
      ["/reconnect"] ->
        {:ok, {:reconnect}}
      _ ->
        {:error, :unknown_command}
    end
  end

  defp parse_attributes(attrs) do
    attrs
    |> String.split(",", trim: true)
    |> Enum.into(%{}, fn(e) -> e
                               |> String.split([" ", ":"], trim: true)
                               |> List.to_tuple end)
  end

  defp parse_wish_age(%{"wish_age" => wish_age} = hash) when is_bitstring(wish_age) do
    wish_age = wish_age
               |> String.trim_leading("[")
               |> String.trim_trailing("]")
               |> String.split("-")
    Map.merge(hash, %{"wish_age" => wish_age})
  end

  defp parse_wish_age(hash) do
    hash
  end

  defp parse_client(client) do
    client
    |> String.downcase
    |> String.to_atom
  end
end

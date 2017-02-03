defmodule NektoBot.Command do
  @moduledoc """
  Module for parsing Telegram commands
  """

  @doc """
  Parses the given message into a command

  ## Examples

      iex> NektoBot.Command.parse "/set A sex: M, age_from: 18"
      {:ok, {:set, "A", %{"sex" => "M", "age_from" => "18"}}}
      iex> NektoBot.Command.parse "/set B sex: W, age_from: 18, age_to: 21"
      {:ok, {:set, "B", %{"sex" => "W", "age_from" => "18", "age_to" => "21"}}}
      iex> NektoBot.Command.parse "/set B sex:M  ,age_from: 18,    age_to: 21"
      {:ok, {:set, "B", %{"sex" => "M", "age_from" => "18", "age_to" => "21"}}}
      iex> NektoBot.Command.parse "/search"
      {:ok, {:search}}
      iex> NektoBot.Command.parse "/search A"
      {:ok, {:search, "A"}}
      iex> NektoBot.Command.parse "/search B"
      {:ok, {:search, "B"}}
      iex> NektoBot.Command.parse "/kick A"
      {:ok, {:kick, "A"}}
      iex> NektoBot.Command.parse "/kick B"
      {:ok, {:kick, "B"}}
      iex> NektoBot.Command.parse "/mute A"
      {:ok, {:mute, "A"}}
      iex> NektoBot.Command.parse "/mute B"
      {:ok, {:mute, "B"}}
      iex> NektoBot.Command.parse "/send A Hello!"
      {:ok, {:send, "A", "Hello!"}}
      iex> NektoBot.Command.parse "/send B Hello!"
      {:ok, {:send, "B", "Hello!"}}

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
        {:ok, {:set, client, attrs |> Enum.join |> parse_attributes}}
      ["/search"] ->
        {:ok, {:search}}
      ["/search", client] when client in ["A", "B"] ->
        {:ok, {:search, client}}
      ["/kick", client] when client in ["A", "B"] ->
        {:ok, {:kick, client}}
      ["/mute", client] when client in ["A", "B"] ->
        {:ok, {:mute, client}}
      ["/send", client | text] when client in ["A", "B"] and text != [] ->
        {:ok, {:send, client, Enum.join(text, " ")}}
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
end

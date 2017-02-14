defmodule Handler do
  @moduledoc """
  Handler for tests
  """

  use GenEvent

  def handle_event(_, state) do
    {:ok, state}
  end
end

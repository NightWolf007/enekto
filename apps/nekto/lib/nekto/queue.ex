defmodule Nekto.Queue do
  @moduledoc """
  Simple FIFO queue implementation
  """

  @doc """
  Starts new empty queue
  """
  def start_link do
    Agent.start_link(fn -> [] end)
  end

  @doc """
  Returns head value from queue
  """
  def get(queue) do
    Agent.get(queue, fn [head | _] -> head end)
  end

  @doc """
  Returns all values queue as list
  """
  def get_all(queue) do
    Agent.get(queue, fn list -> list end)
  end

  @doc """
  Pops head value from queue
  """
  def pop(queue) do
    Agent.get_and_update(queue, fn [head | tail] -> {head, tail} end)
  end

  @doc """
  Pops all values from queue as list
  """
  def pop_all(queue) do
    Agent.get_and_update(queue, fn list -> {list, []} end)
  end

  @doc """
  Puts new value into queue
  """
  def put(queue, value) do
    Agent.update(queue, fn list -> list ++ [value] end)
  end

  @doc """
  Clears queue
  """
  def clear(queue) do
    Agent.update(queue, fn _ -> [] end)
  end

  @doc """
  Stops queue
  """
  def stop(queue) do
    Agent.stop(queue)
  end
end

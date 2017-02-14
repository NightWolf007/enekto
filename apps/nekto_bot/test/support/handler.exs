defmodule Support.Handler do
  use GenEvent

  def wait(gen_event) do
    case GenEvent.call(gen_event, Support.Handler, :messages) do
      nil -> wait(gen_event)
      message -> message
    end
  end

  def flush(gen_event) do
    GenEvent.call(gen_event, Support.Handler, :flush)
  end

  def handle_event({notice, message}, messages) do
    {:ok, [{notice, message} | messages]}
  end

  def handle_call(:messages, []) do
    {:ok, nil, []}
  end

  def handle_call(:messages, messages) do
    [head | tail] = messages
    {:ok, head, tail}
  end

  def handle_call(:flush, messages) do
    {:ok, messages, []}
  end
end

defmodule NektoClient.Headers do
  def find(headers, header) do
    List.foldl(headers, [],
      fn(x, acc) ->
        case x do
          {^header, value} -> [value | acc]
          _ -> acc
        end
      end
    )
  end
end

defmodule NektoBot.InputFsm do
  @moduledoc """
  State machine for user's input
  """

  use Fsm, initial_state: :command_input

  defstate command_input do
    defevent setup(client) do
      next_state(:my_sex_input, client)
    end
  end

  defstate my_sex_input do
    defevent entered(nil), data: client do
      next_state(:my_age_input, client)
    end

    defevent entered(_), data: client do
      next_state(:wish_sex_input, client)
    end

    defevent cancel do
      next_state(:command_input)
    end
  end

  defstate wish_sex_input do
    defevent entered(_), data: client do
      next_state(:my_age_input, client)
    end

    defevent cancel do
      next_state(:command_input)
    end
  end

  defstate my_age_input do
    defevent entered(nil) do
      next_state(:command_input)
    end

    defevent entered(_), data: client do
      next_state(:wish_age_input, client)
    end

    defevent cancel do
      next_state(:command_input)
    end
  end

  defstate wish_age_input do
    defevent entered(_) do
      next_state(:command_input)
    end

    defevent cancel do
      next_state(:command_input)
    end
  end
end

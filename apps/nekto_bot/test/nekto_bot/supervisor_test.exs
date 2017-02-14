defmodule NektoBot.SupervisorTest do
  use ExUnit.Case, async: false

  alias NektoBot.Supervisor
  alias NektoBot.Receiver
  alias NektoBot.Controller
  alias NektoBot.MessagesHandler

  setup do
    Application.ensure_all_started(:nekto_bot)
    {:ok, supervisor} = Supervisor.start_link
    {:ok, supervisor: supervisor}
  end

  describe "Nekto.Supervisor.start_link" do
    test "it adds MessagesHandler to receiver", %{supervisor: supervisor} do
      gen_event = supervisor
                  |> Supervisor.receiver
                  |> Receiver.gen_event
      assert MessagesHandler in GenEvent.which_handlers(gen_event)
    end
  end

  describe "Nekto.Supervisor.controller/1" do
    test "it returns controller's pid", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.controller
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {Controller, :init, 1}
    end
  end

  describe "Nekto.Supervisor.receiver/1" do
    test "it returns receiver's pid", %{supervisor: supervisor} do
      initial_call = supervisor
                     |> Supervisor.receiver
                     |> Process.info(:dictionary)
                     |> elem(1)
                     |> Keyword.get(:"$initial_call")
      assert initial_call == {Receiver, :init, 1}
    end
  end
end

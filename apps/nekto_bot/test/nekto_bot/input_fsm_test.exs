defmodule NektoBot.InputFsmTest do
  use ExUnit.Case, async: true

  alias NektoBot.InputFsm

  setup do
    {:ok, fsm: InputFsm.new, client: :a}
  end

  test "it has command_input as initial_state", %{fsm: fsm} do
    assert fsm.state == :command_input
  end

  describe "command_input state" do
    test "it transits to my_sex_input state on setup",
         %{fsm: fsm, client: client} do
      assert InputFsm.setup(fsm, client).state == :my_sex_input
      assert InputFsm.setup(fsm, client).data == client
    end
  end

  describe "my_sex_input state" do
    setup %{fsm: fsm, client: client} do
      {:ok, fsm: InputFsm.setup(fsm, client), client: client}
    end

    test "it transits to my_age_input state on entered nil",
         %{fsm: fsm, client: client} do
      assert InputFsm.entered(fsm, nil).state == :my_age_input
      assert InputFsm.entered(fsm, nil).data == client
    end

    test "it transits to wish_sex_input state on entered something",
         %{fsm: fsm, client: client} do
      assert InputFsm.entered(fsm, "M").state == :wish_sex_input
      assert InputFsm.entered(fsm, "M").data == client
    end

    test "it transits to command_input state on cancel", %{fsm: fsm} do
      assert InputFsm.cancel(fsm).state == :command_input
    end
  end

  describe "wish_sex_input state" do
    setup %{fsm: fsm, client: client} do
      fsm = fsm |> InputFsm.setup(client) |> InputFsm.entered("M")
      {:ok, fsm: fsm, client: client}
    end

    test "it transits to my_age_input state on entered",
         %{fsm: fsm, client: client} do
      assert InputFsm.entered(fsm, "W").state == :my_age_input
      assert InputFsm.entered(fsm, "W").data == client
    end

    test "it transits to command_input state on cancel", %{fsm: fsm} do
      assert InputFsm.cancel(fsm).state == :command_input
    end
  end

  describe "my_age_input state" do
    setup %{fsm: fsm, client: client} do
      fsm = fsm |> InputFsm.setup(client) |> InputFsm.entered(nil)
      {:ok, fsm: fsm, client: client}
    end

    test "it transits to command_input state on entered nil", %{fsm: fsm} do
      assert InputFsm.entered(fsm, nil).state == :command_input
    end

    test "it transits to wish_age_input state on entered something",
         %{fsm: fsm, client: client} do
      assert InputFsm.entered(fsm, "18t21").state == :wish_age_input
      assert InputFsm.entered(fsm, "18t21").data == client
    end

    test "it transits to command_input state on cancel", %{fsm: fsm} do
      assert InputFsm.cancel(fsm).state == :command_input
    end
  end

  describe "wish_age_input state" do
    setup %{fsm: fsm, client: client} do
      fsm = fsm
            |> InputFsm.setup(client)
            |> InputFsm.entered(nil)
            |> InputFsm.entered("18t21")
      {:ok, fsm: fsm, client: client}
    end

    test "it transits to command_input state on entered", %{fsm: fsm} do
      assert InputFsm.entered(fsm, "18t21").state == :command_input
    end

    test "it transits to command_input state on cancel", %{fsm: fsm} do
      assert InputFsm.cancel(fsm).state == :command_input
    end
  end
end

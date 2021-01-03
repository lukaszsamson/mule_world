defmodule MuleWorl.HeroSupervisorTest do
  use ExUnit.Case, async: false

  alias MuleWorld.HeroSupervisor

  test "starts" do
    assert {:ok, _pid} = HeroSupervisor.start_link([])
  end

  test "starts player" do
    assert {:ok, _pid} = HeroSupervisor.start_link([])

    assert {:ok, _pid} = HeroSupervisor.start_player("some name")
  end

  test "starts player not unique name" do
    assert {:ok, _pid} = HeroSupervisor.start_link([])

    assert {:ok, pid} = HeroSupervisor.start_player("some name")
    assert {:ok, ^pid} = HeroSupervisor.start_player("some name")
  end

  test "stops player" do
    assert {:ok, _pid} = HeroSupervisor.start_link([])

    assert {:ok, pid} = HeroSupervisor.start_player("some name")
    Process.monitor(pid)
    HeroSupervisor.stop_player("some name")
    assert_receive {:DOWN, _, :process, ^pid, :shutdown}
  end
end

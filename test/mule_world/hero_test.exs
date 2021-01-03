defmodule MuleWorl.HeroTest do
  use ExUnit.Case, async: false

  alias MuleWorld.Hero
  alias MuleWorld.Coordinates

  test "starts" do
    assert {:ok, pid} = Hero.start_link(player_name: "test")
    assert %Hero{
      status: :dead,
      position: nil
    } = :sys.get_state(pid)
  end
end

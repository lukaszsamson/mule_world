defmodule MuleWorl.HeroTest do
  use ExUnit.Case, async: false

  alias MuleWorld.Hero
  require MuleWorld.Coordinates, as: Coordinates

  test "starts" do
    assert {:ok, pid} = Hero.start_link(player_name: "test")
    assert %Hero{
      status: :nil,
      position: nil
    } = :sys.get_state(pid)
  end

  test "gets spawned" do
    assert {:ok, pid} = Hero.start_link(player_name: "test")
    send(pid, {:spawned, Coordinates.coordinates(x: 1, y: 1)})
    assert %Hero{
      status: :alive,
      position: Coordinates.coordinates(x: 1, y: 1)
    } = :sys.get_state(pid)
  end

  test "gets moved" do
    assert {:ok, pid} = Hero.start_link(player_name: "test")
    send(pid, {:spawned, Coordinates.coordinates(x: 1, y: 1)})
    send(pid, {:spawned, Coordinates.coordinates(x: 2, y: 1)})
    assert %Hero{
      status: :alive,
      position: Coordinates.coordinates(x: 2, y: 1)
    } = :sys.get_state(pid)
  end

  test "gets attacked" do
    assert {:ok, pid} = Hero.start_link(player_name: "test")
    send(pid, {:spawned, Coordinates.coordinates(x: 1, y: 1)})
    send(pid, :attacked)
    assert %Hero{
      status: :dead,
      position: Coordinates.coordinates(x: 1, y: 1)
    } = :sys.get_state(pid)
  end
end

defmodule MuleWorl.HeroTest do
  use ExUnit.Case, async: false

  alias MuleWorld.Map
  alias MuleWorld.Hero
  require MuleWorld.Coordinates, as: Coordinates

  setup do
    {:ok, _} = Map.start_link([])
    {:ok, %{}}
  end

  test "starts" do
    assert {:ok, pid} = Hero.start_link(player_name: "test")

    assert %Hero{position: {:coordinates, 0, 0}, status: :alive, player_name: "test"} =
             :sys.get_state(pid)
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

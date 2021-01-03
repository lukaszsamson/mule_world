defmodule MuleWorl.MapTest do
  use ExUnit.Case, async: false

  alias MuleWorld.Map
  alias MuleWorld.Hero
  require MuleWorld.Coordinates, as: Coordinates

  test "starts" do
    assert {:ok, pid} = Map.start_link([])
    assert %Map{
      obstacles: obstacles,
      heroes: heroes
    } = :sys.get_state(pid)

    assert heroes == %{}
    assert [Coordinates.coordinates() | _] = obstacles
  end

  test "hero can join and leave" do
    assert {:ok, pid} = Map.start_link([])

    assert {:ok, hero_pid} = Hero.start_link(player_name: "hero 1")

    assert %Map{
      heroes: %{"hero 1" => {^hero_pid, hero}},
      obstacles: obstacles
    } = state = :sys.get_state(pid)

    assert not Map.obstacled?(hero.position, state)

    Process.unlink(hero_pid)
    Process.exit(hero_pid, :shutdown)

    wait_until_heros_down(pid)
  end

  defp wait_until_heros_down(pid) do
    %Map{
      heroes: heroes
    } = :sys.get_state(pid)

    if heroes == %{} do
      :ok
    else
      Process.sleep(100)
      wait_until_heros_down(pid)
    end
  end
end

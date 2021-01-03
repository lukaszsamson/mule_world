defmodule MuleWorl.MapTest do
  use ExUnit.Case, async: false

  alias MuleWorld.Map
  alias MuleWorld.Hero
  require MuleWorld.Coordinates, as: Coordinates

  setup do
    :ok
  end

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
      heroes: %{"hero 1" => {^hero_pid, hero}}
    } = state = :sys.get_state(pid)

    assert not Map.obstacled?(hero.position, state)

    Process.unlink(hero_pid)
    Process.exit(hero_pid, :shutdown)

    wait_until_heros_down(pid)
  end

  test "hero can move" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, hero_pid} = Hero.start_link(player_name: "hero 1")

    assert %Hero{
      position: {:coordinates, 0, 0}
    } = :sys.get_state(hero_pid)

    assert :ok = Hero.move("hero 1", :down)

    assert %Hero{
      position: {:coordinates, 0, 1}
    } = :sys.get_state(hero_pid)

    assert :ok = Hero.move("hero 1", :right)

    assert %Hero{
      position: {:coordinates, 1, 1}
    } = :sys.get_state(hero_pid)
  end

  test "hero cant move through map wall" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, _hero_pid} = Hero.start_link(player_name: "hero 1")

    assert :error = Hero.move("hero 1", :left)
    assert :error = Hero.move("hero 1", :up)
  end

  test "hero cant move through obstacle" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, _hero_pid} = Hero.start_link(player_name: "hero 1")

    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)

    assert :error = Hero.move("hero 1", :right)
  end

  test "hero can move through other hero" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, hero_pid_1} = Hero.start_link(player_name: "hero 1")
    assert {:ok, hero_pid_2} = Hero.start_link(player_name: "hero 2")

    assert %Hero{
      position: {:coordinates, 9, 2}
    } = :sys.get_state(hero_pid_2)

    :ok = Hero.move("hero 1", :down)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)

    assert :ok = Hero.move("hero 1", :down)

    assert %Hero{
      position: {:coordinates, 9, 2}
    } = :sys.get_state(hero_pid_1)
  end

  test "hero can attack other hero" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, _hero_pid_1} = Hero.start_link(player_name: "hero 1")
    assert {:ok, hero_pid_2} = Hero.start_link(player_name: "hero 2")

    assert %Hero{
      position: {:coordinates, 9, 2}
    } = :sys.get_state(hero_pid_2)

    :ok = Hero.move("hero 1", :down)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)

    assert :ok = Hero.attack("hero 1")

    assert %Hero{
      status: :dead
    } = :sys.get_state(hero_pid_2)
  end

  test "dead hero cannot move and attack" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, _hero_pid_1} = Hero.start_link(player_name: "hero 1")
    assert {:ok, hero_pid_2} = Hero.start_link(player_name: "hero 2")

    assert %Hero{
      position: {:coordinates, 9, 2}
    } = :sys.get_state(hero_pid_2)

    :ok = Hero.move("hero 1", :down)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)

    assert :ok = Hero.attack("hero 1")

    assert %Hero{
      status: :dead
    } = :sys.get_state(hero_pid_2)

    assert :error = Hero.attack("hero 2")
    assert :error = Hero.move("hero 2", :up)
  end

  test "dead hero respawns in 5s" do
    assert {:ok, _pid} = Map.start_link([])

    assert {:ok, _hero_pid_1} = Hero.start_link(player_name: "hero 1")
    assert {:ok, hero_pid_2} = Hero.start_link(player_name: "hero 2")

    assert %Hero{
      position: {:coordinates, 9, 2}
    } = :sys.get_state(hero_pid_2)

    :ok = Hero.move("hero 1", :down)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)
    :ok = Hero.move("hero 1", :right)

    assert :ok = Hero.attack("hero 1")

    assert %Hero{
      status: :dead
    } = :sys.get_state(hero_pid_2)

    Process.sleep(5200)
    assert %Hero{
      status: :alive
    } = :sys.get_state(hero_pid_2)
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

defmodule MuleWorld.Map do
  use GenServer

  require MuleWorld.Coordinates, as: Coordinates
  alias MuleWorld.Hero

  @map_size 10

  defstruct [
    :obstacles,
    :heroes
  ]

  @type status_t :: :dead | :alive

  @type t :: %__MODULE__{
    obstacles: [Coordinates.t],
    heroes: %{
      optional(String.t) => {pid, Hero.t}
    }
  }

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def join(hero_pid, player_name) do
    GenServer.cast(__MODULE__, {:join, hero_pid, player_name})
  end

  def move(player_name, direction) do
    GenServer.cast(__MODULE__, {:move, player_name, direction})
  end

  @impl true
  def init(_arg) do
    {:ok, %__MODULE__{
      obstacles: generate_obstacles(),
      heroes: %{}
    }}
  end

  @impl true
  def handle_cast({:join, hero_pid, player_name}, state) do
    Process.monitor(hero_pid)

    hero = %Hero{
      position: get_free_coordinate(state),
      status: :alive
    }

    heroes = state.heroes
    |> Map.put(player_name, {hero_pid, hero})

    send(hero_pid, {:spawned, hero.position})

    {:noreply, %{state | heroes: heroes}}
  end

  @impl true
  def handle_call({:attack, player_name}, _from, state) do
    attacked_coordinates = state.heroes[player_name].position
    |> get_attacked_coordinates()

    attacked_heroes = state.heroes
    |> Enum.filter(fn {name, {_pid, hero}} ->
      name != player_name and hero.status == :alive and hero.position in attacked_coordinates
    end)
    |> Enum.map(fn {name, {pid, hero}} ->
      {name, {pid, %{hero | status: :dead}}}
    end)

    for {_name, {pid, _hero}} <- attacked_heroes do
      send(pid, :attacked)
    end

    {:reply, :ok, %{state | heroes: state.heroes |> Map.merge(Map.new(attacked_heroes))}}
  end

  def handle_call({:move, player_name, direction}, _from, state = %__MODULE__{heroes: heroes}) do
    new_position = heroes[player_name].position
    |> Coordinates.move(direction)

    result = if on_map?(new_position) and not obstacled?(new_position, state) do
      :ok
    else
      :error
    end
    {:reply, result, state}
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, _}, state) do
    heroes = state.heroes
    |> Enum.reject(&match?({_name, {^pid, _}}, &1))
    |> Map.new

    {:noreply, %{state | heroes: heroes}}
  end

  def generate_obstacles() do
    obstacle_number = Enum.random(1..30)
    for _ <- 1..obstacle_number, uniq: true do
      get_random_coordinates()
    end
  end

  def get_random_coordinates() do
    x = Enum.random(0..(@map_size - 1))
    y = Enum.random(0..(@map_size - 1))
    Coordinates.coordinates(x: x, y: y)
  end

  def get_free_coordinate(state) do
    coordinates = get_random_coordinates()

    if obstacled?(coordinates, state) do
      get_free_coordinate(state)
    else
      coordinates
    end
  end

  def on_map?(Coordinates.coordinates(x: x, y: y)) do
    x >= 0 and y >= 0 and x < @map_size and y < @map_size
  end

  def obstacled?(coordinates, %__MODULE__{obstacles: obstacles}) do
    coordinates in obstacles
  end

  def get_attacked_coordinates(Coordinates.coordinates(x: x0, y: y0)) do
    for x <- (x0 - 1)..(x0 + 1),
      y <- (y0 - 1)..(y0 + 1) do
        Coordinates.coordinates(x: x, y: y)
      end
  end
end

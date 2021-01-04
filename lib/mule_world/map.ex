defmodule MuleWorld.Map do
  use GenServer

  require MuleWorld.Coordinates, as: Coordinates
  alias MuleWorld.Hero

  @map_size 10
  @respawn_timeout 5000

  defstruct [
    :obstacles,
    :heroes
  ]

  @type t :: %__MODULE__{
          obstacles: [Coordinates.t()],
          heroes: %{
            optional(String.t()) => {pid, Hero.t()}
          }
        }

  @table_name :"#{__MODULE__}_table"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def join(player_name) do
    GenServer.call(__MODULE__, {:join, player_name})
  end

  def move(player_name, direction) do
    GenServer.call(__MODULE__, {:move, player_name, direction})
  end

  def attack(player_name) do
    GenServer.call(__MODULE__, {:attack, player_name})
  end

  @spec get_heroes :: %{
          optional(String.t()) => Hero.t()
        }
  def get_heroes() do
    case :ets.lookup(@table_name, :heroes) do
      [{_key, value}] ->
        value

      [] ->
        %{}
    end
  end

  @spec get_obstacles :: [Coordinates.t()]
  def get_obstacles() do
    case :ets.lookup(@table_name, :obstacles) do
      [{_key, value}] ->
        value

      [] ->
        []
    end
  end

  def map_size, do: @map_size

  @impl true
  def init(_arg) do
    if Mix.env() == :test do
      # make tests not random
      :rand.seed(:exsss, {11, 12, 10})
    end

    :ets.new(@table_name, [
      :set,
      :named_table,
      :protected,
      read_concurrency: true,
      write_concurrency: false
    ])

    state = %__MODULE__{
      obstacles: generate_obstacles(),
      heroes: %{}
    }

    :ets.insert(@table_name, {:obstacles, state.obstacles})

    update_table_and_notify(state)

    {:ok, state}
  end

  @impl true
  def handle_call({:join, player_name}, {hero_pid, _ref}, state) do
    Process.monitor(hero_pid)

    position = get_free_coordinate(state)

    hero = Hero.new(player_name, position)

    heroes =
      state.heroes
      |> Map.put(player_name, {hero_pid, hero})

    state = %__MODULE__{state | heroes: heroes}

    update_table_and_notify(state)

    {:reply, position, state}
  end

  def handle_call({:attack, player_name}, _from, state) do
    hero = elem(state.heroes[player_name], 1)

    {result, heroes} =
      if hero.status == :alive do
        attacked_coordinates =
          hero.position
          |> get_attacked_coordinates()

        attacked_heroes =
          state.heroes
          |> Enum.filter(fn {name, {_pid, hero}} ->
            name != player_name and hero.status == :alive and
              hero.position in attacked_coordinates
          end)
          |> Enum.map(fn {name, {pid, hero}} ->
            {name, {pid, Hero.attacked(hero)}}
          end)

        for {name, {pid, hero}} <- attacked_heroes do
          send(pid, :attacked)

          if hero.status == :dead do
            Process.send_after(self(), {:respawn, name}, @respawn_timeout)
          end
        end

        {:ok, state.heroes |> Map.merge(Map.new(attacked_heroes))}
      else
        {{:error, :dead}, state.heroes}
      end

    state = %__MODULE__{state | heroes: heroes}

    update_table_and_notify(state)

    {:reply, result, state}
  end

  def handle_call({:move, player_name, direction}, {pid, _ref}, state = %__MODULE__{}) do
    hero = elem(state.heroes[player_name], 1)

    result =
      if hero.status == :alive do
        new_position =
          hero.position
          |> Coordinates.move(direction)

        cond do
          not on_map?(new_position) ->
            {:error, :map_boundary}

          obstacled?(new_position, state) ->
            {:error, :obstacled}

          true ->
            {:ok, new_position}
        end
      else
        {:error, :dead}
      end

    state =
      case result do
        {:ok, new_position} ->
          hero = Hero.moved(hero, new_position)
          %__MODULE__{state | heroes: Map.put(state.heroes, player_name, {pid, hero})}

        _ ->
          state
      end

    update_table_and_notify(state)

    {:reply, result, state}
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, _}, state) do
    heroes =
      state.heroes
      |> Enum.reject(&match?({_name, {^pid, _}}, &1))
      |> Map.new()

    state = %__MODULE__{state | heroes: heroes}

    update_table_and_notify(state)

    {:noreply, state}
  end

  def handle_info({:respawn, name}, state) do
    heroes =
      case state.heroes[name] do
        {pid, hero} ->
          position = get_free_coordinate(state)
          send(pid, {:spawned, position})

          state.heroes
          |> Map.put(name, {pid, Hero.spawned(hero, position)})

        nil ->
          state.heroes
      end

    state = %__MODULE__{state | heroes: heroes}

    update_table_and_notify(state)

    {:noreply, state}
  end

  def generate_obstacles() do
    obstacle_number = Enum.random(1..15)

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

  defp update_table_and_notify(state) do
    heroes =
      for {name, {_pid, hero}} <- state.heroes,
          into: %{},
          do: {name, hero}

    :ets.insert(@table_name, {:heroes, heroes})

    Phoenix.PubSub.broadcast(MuleWorld.PubSub, "game", :map_updated)
  end
end

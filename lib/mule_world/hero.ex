defmodule MuleWorld.Hero do
  use GenServer

  alias MuleWorld.Map
  alias MuleWorld.Coordinates

  defstruct [
    :position,
    :status,
    :player_name
  ]

  @type status_t :: :dead | :alive

  @type t :: %__MODULE__{
          position: Coordinates.t(),
          status: status_t,
          player_name: String.t()
        }

  def via_tuple(player_name) do
    {:via, Registry, {MuleWorld.PlayerRegistry, player_name}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(Keyword.fetch!(args, :player_name)))
  end

  def move(player_name, direction) do
    GenServer.call(via_tuple(player_name), {:move, direction})
  end

  def attack(player_name) do
    GenServer.call(via_tuple(player_name), :attack)
  end

  @impl true
  def init(args) do
    player_name = Keyword.fetch!(args, :player_name)
    position = Map.join(player_name)

    {:ok, new(player_name, position)}
  end

  @impl true
  def handle_call({:move, direction}, _from, state = %__MODULE__{}) do
    result =
      if state.status == :alive do
        Map.move(state.player_name, direction)
      else
        {:error, :dead}
      end

    {result, state} =
      case result do
        {:ok, new_position} ->
          {:ok, moved(state, new_position)}

        other ->
          {other, state}
      end

    {:reply, result, state}
  end

  def handle_call(:attack, _from, state = %__MODULE__{}) do
    result =
      if state.status == :alive do
        Map.attack(state.player_name)
      else
        {:error, :dead}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_info(:attacked, state = %__MODULE__{}) do
    state = attacked(state)

    {:noreply, state}
  end

  def handle_info({:spawned, position}, state = %__MODULE__{}) do
    state = spawned(state, position)

    {:noreply, state}
  end

  @spec new(String.t(), Coordinates.t()) :: Hero.t()
  def new(player_name, position),
    do: %__MODULE__{
      player_name: player_name,
      status: :alive,
      position: position
    }

  @spec attacked(Hero.t()) :: Hero.t()
  def attacked(state = %__MODULE__{}), do: %__MODULE__{state | status: :dead}

  @spec spawned(Hero.t(), Coordinates.t()) :: Hero.t()
  def spawned(state = %__MODULE__{}, position),
    do: %__MODULE__{state | status: :alive, position: position}

  @spec moved(Hero.t(), Coordinates.t()) :: Hero.t()
  def moved(state = %__MODULE__{}, position), do: %__MODULE__{state | position: position}
end

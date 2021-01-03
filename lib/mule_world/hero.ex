defmodule MuleWorld.Hero do
  use GenServer

  alias MuleWorld.Map
  alias MuleWorld.Coordinates

  defstruct [
    :position,
    :status,
    :player_name
  ]

  @type status_t :: :dead | :alive | nil

  @type t :: %__MODULE__{
          position: Coordinates.t() | nil,
          status: status_t,
          player_name: String.t
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
    {:ok, %__MODULE__{
      player_name: player_name,
      status: :alive,
      position: position
    }}
  end

  @impl true
  def handle_call({:move, direction}, _from, state = %__MODULE__{}) do
    result = if state.status == :alive do
      Map.move(state.player_name, direction)
    else
      :error
    end

    {result, state} = case result do
      {:ok, new_position} ->
        {:ok, %{state | position: new_position}}
      other ->
        {other, state}
    end

    {:reply, result, state}
  end

  def handle_call(:attack, _from, state = %__MODULE__{}) do
    result = if state.status == :alive do
      Map.attack(state.player_name)
    else
      :error
    end
    {:reply, result, state}
  end

  @impl true
  def handle_info(:attacked, state = %__MODULE__{}) do
    state = %__MODULE__{state |
      status: :dead
    }

    {:noreply, state}
  end

  def handle_info({:spawned, position}, state = %__MODULE__{}) do
    state = %__MODULE__{state |
      status: :alive,
      position: position
    }

    {:noreply, state}
  end
end

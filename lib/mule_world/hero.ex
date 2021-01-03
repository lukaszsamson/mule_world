defmodule MuleWorld.Hero do
  use GenServer

  alias MuleWorld.Map
  alias MuleWorld.Coordinates

  defstruct [
    :position,
    :status
  ]

  @type status_t :: :dead | :alive | nil

  @type t :: %__MODULE__{
          position: Coordinates.t() | nil,
          status: status_t
        }

  def via_tuple(player_name) do
    {:via, Registry, {MuleWorld.PlayerRegistry, player_name}}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(Keyword.fetch!(args, :player_name)))
  end

  @impl true
  def init(args) do
    Map.join(self(), Keyword.fetch!(args, :player_name))
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_info(:attacked, state = %__MODULE__{}) do
    state = %__MODULE__{state |
      status: :dead
    }

    {:noreply, state}
  end

  def handle_info({:moved, position}, state = %__MODULE__{}) do
    state = %__MODULE__{state |
      position: position
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

  # def handle_call(:attack, state = %__MODULE__{}) do
  #   result = if state.status == :alive do
  #     Map.attack()
  #   else
  #     :error
  #   end
  #   {:reply, result, state}
  # end
end

defmodule MuleWorld.Hero do
  use GenServer

  alias MuleWorld.Coordinates

  defstruct [
    :position,
    :status
  ]

  @type status_t :: :dead | :alive

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
  def init(_arg) do
    {:ok, %__MODULE__{
      status: :dead,
      position: nil
    }}
  end

  @impl true
  def handle_info(:attacked, state = %__MODULE__{}) do
    state = %__MODULE__{state |
      status: :dead,
      # TODO
      position: nil
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

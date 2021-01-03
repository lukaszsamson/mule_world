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

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
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

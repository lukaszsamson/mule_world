defmodule MuleWorld.Hero do
  use GenServer

  alias MuleWorld.Coordinates

  defstruct [
    :position,
    :status
  ]

  @type status_t :: :dead | :alive

  @type t :: %__MODULE__{
          position: Coordinates.t(),
          status: status_t
        }

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    {:ok, %__MODULE__{}}
  end
end

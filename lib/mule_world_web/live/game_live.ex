defmodule MuleWorldWeb.GameLive do
  use MuleWorldWeb, :live_view
  require MuleWorld.Coordinates, as: Coordinates

  @impl true
  def mount(params, _session, socket) do
    player_name = params["player_name"] || random_name()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MuleWorld.PubSub, "game")
    end

    MuleWorld.HeroSupervisor.start_player(player_name)

    %{
      obstacles: obstacles,
      heroes: heroes
    } = MuleWorld.Map.get()

    {:ok, assign(socket, player_name: player_name, obstacles: obstacles, heroes: heroes)}
  end

  @impl true
  def handle_info(:map_updated, socket) do
    %{
      obstacles: obstacles,
      heroes: heroes
    } = MuleWorld.Map.get()

    {:noreply, assign(socket, obstacles: obstacles, heroes: heroes)}
  end

  @impl true
  def handle_event("game", %{"key" => "ArrowUp"}, socket) do
    MuleWorld.Hero.move(socket.assigns.player_name, :up)
    {:noreply, socket}
  end

  def handle_event("game", %{"key" => "ArrowDown"}, socket) do
    MuleWorld.Hero.move(socket.assigns.player_name, :down)
    {:noreply, socket}
  end

  def handle_event("game", %{"key" => "ArrowLeft"}, socket) do
    MuleWorld.Hero.move(socket.assigns.player_name, :left)
    {:noreply, socket}
  end

  def handle_event("game", %{"key" => "ArrowRight"}, socket) do
    MuleWorld.Hero.move(socket.assigns.player_name, :right)
    {:noreply, socket}
  end

  def handle_event("game", %{"key" => " "}, socket) do
    MuleWorld.Hero.attack(socket.assigns.player_name)
    {:noreply, socket}
  end

  def handle_event("game", %{"key" => _}, socket) do
    {:noreply, socket}
  end

  defp random_name(), do: :crypto.strong_rand_bytes(6) |> Base.url_encode64()

  def get_class(x, y, obstacles, heroes, player_name) do
    position = Coordinates.coordinates(x: x, y: y)

    player_hero =
      case heroes[player_name] do
        {_, %{position: ^position, status: :alive}} = hero -> hero
        _ -> nil
      end

    alive_enemy =
      Enum.find(heroes, fn {_name, {_pid, hero}} ->
        hero.position == position and hero.status == :alive
      end)

    dead = Enum.find(heroes, fn {_name, {_pid, hero}} -> hero.position == position end)

    cond do
      position in obstacles -> "mule-obstacle"
      player_hero != nil -> "mule-hero"
      alive_enemy != nil -> "mule-enemy"
      dead != nil -> "mule-dead"
      true -> ""
    end
  end
end

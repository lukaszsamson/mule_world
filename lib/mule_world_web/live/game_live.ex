defmodule MuleWorldWeb.GameLive do
  use MuleWorldWeb, :live_view
  require MuleWorld.Coordinates, as: Coordinates
  alias MuleWorld.Hero

  @impl true
  def mount(params, _session, socket) do
    player_name = params["player_name"] || random_name()

    if connected?(socket) do
      Phoenix.PubSub.subscribe(MuleWorld.PubSub, "game")
    end

    MuleWorld.HeroSupervisor.start_player(player_name)

    {:ok,
     assign(socket,
       player_name: player_name,
       obstacles: MuleWorld.Map.get_obstacles(),
       heroes: MuleWorld.Map.get_heroes(),
       error: nil
     )}
  end

  @impl true
  def handle_info(:map_updated, socket) do
    {:noreply, assign(socket, heroes: MuleWorld.Map.get_heroes())}
  end

  @impl true
  def handle_event("game", %{"key" => "ArrowUp"}, socket) do
    result = MuleWorld.Hero.move(socket.assigns.player_name, :up)
    {:noreply, socket |> handle_error(result)}
  end

  def handle_event("game", %{"key" => "ArrowDown"}, socket) do
    result = MuleWorld.Hero.move(socket.assigns.player_name, :down)
    {:noreply, socket |> handle_error(result)}
  end

  def handle_event("game", %{"key" => "ArrowLeft"}, socket) do
    result = MuleWorld.Hero.move(socket.assigns.player_name, :left)
    {:noreply, socket |> handle_error(result)}
  end

  def handle_event("game", %{"key" => "ArrowRight"}, socket) do
    result = MuleWorld.Hero.move(socket.assigns.player_name, :right)
    {:noreply, socket |> handle_error(result)}
  end

  def handle_event("game", %{"key" => " "}, socket) do
    result = MuleWorld.Hero.attack(socket.assigns.player_name)
    {:noreply, socket |> handle_error(result)}
  end

  def handle_event("game", %{"key" => _}, socket) do
    {:noreply, socket |> handle_error(:ok)}
  end

  defp random_name(), do: :crypto.strong_rand_bytes(6) |> Base.url_encode64()

  def get_class(x, y, obstacles, heroes, player_name) do
    position = Coordinates.coordinates(x: x, y: y)

    {player_hero, alive_enemy, dead} = get_heroes_by_coordinates(position, heroes, player_name)

    cond do
      position in obstacles -> "mule-obstacle"
      player_hero != nil -> "mule-hero"
      alive_enemy != nil -> "mule-enemy"
      dead != nil -> "mule-dead"
      true -> ""
    end
  end

  def get_hero_name(x, y, heroes, player_name) do
    position = Coordinates.coordinates(x: x, y: y)

    {player_hero, alive_enemy, dead} = get_heroes_by_coordinates(position, heroes, player_name)

    cond do
      player_hero != nil -> player_hero.player_name
      alive_enemy != nil -> alive_enemy.player_name
      dead != nil -> dead.player_name
      true -> nil
    end
  end

  defp get_heroes_by_coordinates(position, heroes, player_name) do
    player_hero =
      case heroes[player_name] do
        %Hero{position: ^position, status: :alive} = hero -> hero
        _ -> nil
      end

    alive_enemy =
      Enum.find(heroes, fn {_name, hero = %Hero{}} ->
        hero.position == position and hero.status == :alive
      end)

    dead = Enum.find(heroes, fn {_name, hero = %Hero{}} -> hero.position == position end)

    {player_hero, if(alive_enemy, do: alive_enemy |> elem(1)), if(dead, do: dead |> elem(1))}
  end

  defp handle_error(socket, :ok), do: socket |> assign(:error, nil)
  defp handle_error(socket, {:error, reason}), do: socket |> assign(:error, inspect(reason))
end

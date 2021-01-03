defmodule MuleWorld.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Start the Ecto repository
        MuleWorld.Repo,
        # Start the Telemetry supervisor
        MuleWorldWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: MuleWorld.PubSub},
        # Start the Endpoint (http/https)
        MuleWorldWeb.Endpoint,
        {Registry, keys: :unique, name: MuleWorld.PlayerRegistry}

        # Start a worker by calling: MuleWorld.Worker.start_link(arg)
        # {MuleWorld.Worker, arg}
      ] ++
        if Mix.env() != :test do
          [MuleWorld.HeroSupervisor, MuleWorld.Map]
        else
          []
        end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MuleWorld.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MuleWorldWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

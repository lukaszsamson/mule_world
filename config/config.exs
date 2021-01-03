# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :mule_world,
  ecto_repos: [MuleWorld.Repo]

# Configures the endpoint
config :mule_world, MuleWorldWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "dAtgbK3kChLYSEKVVyMdL74ExXclTC4Tv7kNHYMgVocpB+sbXdzw68f5x0mF0+en",
  render_errors: [view: MuleWorldWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MuleWorld.PubSub,
  live_view: [signing_salt: "POeK2Dxy"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

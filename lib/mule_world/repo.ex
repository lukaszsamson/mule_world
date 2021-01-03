defmodule MuleWorld.Repo do
  use Ecto.Repo,
    otp_app: :mule_world,
    adapter: Ecto.Adapters.Postgres
end

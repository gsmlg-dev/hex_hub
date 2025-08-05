defmodule HexHub.Repo do
  use Ecto.Repo,
    otp_app: :hex_hub,
    adapter: Ecto.Adapters.Postgres
end

defmodule FlappyElixir.Repo do
  use Ecto.Repo,
    otp_app: :flappy_elixir,
    adapter: Ecto.Adapters.Postgres
end

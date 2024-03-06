defmodule LittleRetro.Repo do
  use Ecto.Repo,
    otp_app: :little_retro,
    adapter: Ecto.Adapters.Postgres
end

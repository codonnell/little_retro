defmodule LittleRetro.Retros.EventHandlers.RetroUsersProjection do
  use Ecto.Schema

  schema "retro_users_projections" do
    field(:retro_id, :binary_id)
    field(:user_email, :string)
    field(:user_id, :integer)
    timestamps()
  end
end

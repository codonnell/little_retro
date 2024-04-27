defmodule LittleRetro.Repo.Migrations.CreateRetroUsersProjection do
  use Ecto.Migration

  def change do
    create table(:retro_users_projections) do
      add(:retro_id, :binary_id, null: false)
      add(:user_id, :integer)
      add(:user_email, :text)

      timestamps(type: :naive_datetime_usec)
    end

    create unique_index(:retro_users_projections, [:retro_id, :user_id])
    create unique_index(:retro_users_projections, [:retro_id, :user_email])
    create index(:retro_users_projections, [:user_id, :inserted_at])
    create index(:retro_users_projections, [:user_email, :inserted_at])
  end
end

defmodule LittleRetro.Retros.EventHandlers.RetroUsersProjector do
  alias LittleRetro.Retros.Events.UserRemovedByEmail
  alias LittleRetro.Retros.Events.UserAddedByEmail
  alias LittleRetro.Retros.EventHandlers.RetroUsersProjection
  alias LittleRetro.Retros.Events.RetroCreated

  use Commanded.Projections.Ecto,
    application: LittleRetro.CommandedApplication,
    repo: LittleRetro.Repo,
    name: "retro_users_projection",
    consistency: Application.compile_env!(:little_retro, :consistency)

  project(%RetroCreated{retro_id: retro_id, moderator_id: moderator_id}, fn multi ->
    Ecto.Multi.insert(
      multi,
      :retro_users_projection,
      %RetroUsersProjection{
        retro_id: retro_id,
        user_id: moderator_id
      },
      on_conflict: :nothing
    )
  end)

  project(%UserAddedByEmail{retro_id: retro_id, email: email}, fn multi ->
    Ecto.Multi.insert(
      multi,
      :retro_users_projection,
      %RetroUsersProjection{
        retro_id: retro_id,
        user_email: email
      },
      on_conflict: :nothing
    )
  end)

  project(%UserRemovedByEmail{retro_id: retro_id, email: email}, fn multi ->
    Ecto.Multi.delete_all(
      multi,
      :retro_users_projection,
      from(ru in RetroUsersProjection,
        where: ru.retro_id == ^retro_id and ru.user_email == ^email
      )
    )
  end)
end

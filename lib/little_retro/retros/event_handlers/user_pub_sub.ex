defmodule LittleRetro.Retros.EventHandlers.UserPubSub do
  alias LittleRetro.Retros.Events.UserRemovedByEmail
  alias Phoenix.PubSub
  alias LittleRetro.Retros.Events.UserAddedByEmail
  alias LittleRetro.CommandedApplication

  use Commanded.Event.Handler,
    application: CommandedApplication,
    name: "UserPubSub",
    start_from: :current

  def handle(%UserAddedByEmail{retro_id: retro_id, email: email}, _metadata) do
    PubSub.broadcast(LittleRetro.PubSub, "retro_users:#{retro_id}", {:user_added_by_email, email})
  end

  def handle(%UserRemovedByEmail{retro_id: retro_id, email: email}, _metadata) do
    PubSub.broadcast(
      LittleRetro.PubSub,
      "retro_users:#{retro_id}",
      {:user_removed_by_email, email}
    )
  end
end

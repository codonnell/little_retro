defmodule LittleRetro.Retros.EventHandlers.UserPubSub do
  alias LittleRetro.Retros.Events.UserRemovedByEmail
  alias Phoenix.PubSub
  alias LittleRetro.Retros.Events.UserAddedByEmail
  alias LittleRetro.CommandedApplication

  use Commanded.Event.Handler,
    application: CommandedApplication,
    name: "UserPubSub",
    start_from: :current

  def handle(%UserAddedByEmail{id: id, email: email}, _metadata) do
    IO.puts("Publishing add with id: #{id}, email: #{email} to retro_users:#{id}")
    IO.inspect({:user_added_by_email, email})
    PubSub.broadcast(LittleRetro.PubSub, "retro_users:#{id}", {:user_added_by_email, email})
  end

  def handle(%UserRemovedByEmail{id: id, email: email}, _metadata) do
    IO.puts("Publishing remove with id: #{id}, email: #{email} to retro_users:#{id}")
    IO.inspect({:user_removed_by_email, email})
    PubSub.broadcast(LittleRetro.PubSub, "retro_users:#{id}", {:user_removed_by_email, email})
  end
end

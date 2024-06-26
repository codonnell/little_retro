defmodule LittleRetro.Retros.EventHandlers.RetroPubSub do
  alias LittleRetro.Retros.Events.DiscussionMovedBack
  alias LittleRetro.Retros.Events.DiscussionAdvanced
  alias LittleRetro.Retros.Events.ActionItemRemoved
  alias LittleRetro.Retros.Events.ActionItemTextEdited
  alias LittleRetro.Retros.Events.ActionItemCreated
  alias LittleRetro.Retros.Events.UserRemovedVoteFromCard
  alias LittleRetro.Retros.Events.UserVotedForCard
  alias LittleRetro.Retros.Events.CardRemovedFromGroup
  alias LittleRetro.Retros.Events.CardsGrouped
  alias LittleRetro.Retros.Events.PhaseChanged
  alias LittleRetro.Retros.Events.CardDeleted
  alias LittleRetro.Retros.Events.CardTextEdited
  alias LittleRetro.Retros.Events.CardCreated
  alias LittleRetro.Retros
  alias LittleRetro.Retros.Events.UserRemovedByEmail
  alias Phoenix.PubSub
  alias LittleRetro.Retros.Events.UserAddedByEmail
  alias LittleRetro.CommandedApplication

  use Commanded.Event.Handler,
    application: CommandedApplication,
    name: "RetroPubSub",
    start_from: :current

  def handle(%UserAddedByEmail{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%UserRemovedByEmail{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  # The atom `:author_id` doesn't exist elsewhere. We need it here to ensure the atom exists before JSON deserialization
  def handle(%CardCreated{retro_id: retro_id, id: id, author_id: _author_id}, _metadata) do
    broadcast(retro_id, {:card_created, %{retro: Retros.get(retro_id), card_id: id}})
  end

  def handle(%CardTextEdited{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%CardDeleted{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%PhaseChanged{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(event = %CardsGrouped{retro_id: retro_id}, _metadata) do
    broadcast(retro_id, {:cards_grouped, %{card_id: event.card_id, retro: Retros.get(retro_id)}})
  end

  def handle(event = %CardRemovedFromGroup{retro_id: retro_id}, _metadata) do
    broadcast(
      retro_id,
      {:card_removed_from_group, %{card_id: event.card_id, retro: Retros.get(retro_id)}}
    )
  end

  def handle(%UserVotedForCard{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%UserRemovedVoteFromCard{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%ActionItemCreated{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%ActionItemTextEdited{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%ActionItemRemoved{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%DiscussionAdvanced{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  def handle(%DiscussionMovedBack{retro_id: retro_id}, _metadata) do
    broadcast_retro(retro_id)
  end

  defp broadcast_retro(retro_id) do
    broadcast(retro_id, {:retro_updated, Retros.get(retro_id)})
  end

  defp broadcast(retro_id, msg) do
    PubSub.broadcast(LittleRetro.PubSub, "retro:#{retro_id}", msg)
  end
end

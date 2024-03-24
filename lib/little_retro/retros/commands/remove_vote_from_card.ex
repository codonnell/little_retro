defmodule LittleRetro.Retros.Commands.RemoveVoteFromCard do
  alias LittleRetro.Retros.Aggregates.Retro.Card
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :user_id, integer(), enforce: true
    field :card_id, Card.id(), enforce: true
  end
end

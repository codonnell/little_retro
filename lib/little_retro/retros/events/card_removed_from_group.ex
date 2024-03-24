defmodule LittleRetro.Retros.Events.CardRemovedFromGroup do
  @derive Jason.Encoder
  alias LittleRetro.Retros.Aggregates.Retro.Card
  use TypedStruct

  typedstruct do
    field :retro_id, Retro.retro_id(), enforce: true
    field :user_id, integer(), enforce: true
    field :card_id, Card.id(), enforce: true
  end
end

defmodule LittleRetro.Retros.Events.CardsGrouped do
  alias LittleRetro.Retros.Aggregates.Retro.Card
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :retro_id, Retro.retro_id(), enforce: true
    field :user_id, integer(), enforce: true
    field :card_id, Card.id(), enforce: true
    field :onto, Card.id(), enforce: true
  end
end
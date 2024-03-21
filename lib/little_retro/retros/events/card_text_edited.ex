defmodule LittleRetro.Retros.Events.CardTextEdited do
  alias LittleRetro.Retros.Aggregates.Retro.Card
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :id, Card.id(), enforce: true
    field :text, String.t(), enforce: true
    field :retro_id, String.t(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

defmodule LittleRetro.Retros.Commands.EditCardText do
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Aggregates.Retro.Card
  use TypedStruct

  typedstruct do
    field :id, Card.id(), enforce: true
    field :text, String.t(), enforce: true
    field :retro_id, Retro.retro_id(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

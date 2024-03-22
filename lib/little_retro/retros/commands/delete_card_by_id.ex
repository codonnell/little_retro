defmodule LittleRetro.Retros.Commands.DeleteCardById do
  alias LittleRetro.Retros.Aggregates.Retro.Card
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :id, Card.id(), enforce: true
    field :column_id, integer(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

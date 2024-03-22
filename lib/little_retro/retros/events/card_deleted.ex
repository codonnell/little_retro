defmodule LittleRetro.Retros.Events.CardDeleted do
  alias LittleRetro.Retros.Aggregates.Retro.Column
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :retro_id, String.t(), enforce: true
    field :author_id, integer(), enforce: true
    field :column_id, Column.id(), enforce: true
  end
end

defmodule LittleRetro.Retros.Commands.EditActionItemText do
  alias LittleRetro.Retros.Aggregates.Retro
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :text, String.t(), enforce: true
    field :retro_id, Retro.retro_id(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

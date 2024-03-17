defmodule LittleRetro.Retros.Commands.CreateCard do
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :column_id, integer(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

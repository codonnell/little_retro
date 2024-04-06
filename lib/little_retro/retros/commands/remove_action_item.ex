defmodule LittleRetro.Retros.Commands.RemoveActionItem do
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :retro_id, String.t(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

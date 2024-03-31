defmodule LittleRetro.Retros.Commands.CreateActionItem do
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

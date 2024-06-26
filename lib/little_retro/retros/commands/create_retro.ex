defmodule LittleRetro.Retros.Commands.CreateRetro do
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :moderator_id, Integer.t(), enforce: true
  end
end

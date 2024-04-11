defmodule LittleRetro.Retros.Commands.AdvanceDiscussion do
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :user_id, integer(), enforce: true
  end
end

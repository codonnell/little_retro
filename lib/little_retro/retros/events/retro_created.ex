defmodule LittleRetro.Retros.Events.RetroCreated do
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :moderator_id, Integer.t(), enforce: true
  end
end

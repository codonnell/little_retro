defmodule LittleRetro.Retros.Events.RetroCreated do
  use TypedStruct

  typedstruct do
    field :id, String.t()
    field :moderator_id, Integer.t()
  end
end

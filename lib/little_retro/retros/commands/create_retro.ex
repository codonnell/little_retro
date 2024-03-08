defmodule LittleRetro.Retros.Commands.CreateRetro do
  use TypedStruct

  typedstruct do
    field :id, String.t()
    field :moderator_id, Integer.t()
  end
end

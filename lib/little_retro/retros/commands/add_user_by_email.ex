defmodule LittleRetro.Retros.Commands.AddUserByEmail do
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :email, String.t(), enforce: true
  end
end

defmodule LittleRetro.Retros.Commands.RemoveUserByEmail do
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :email, String.t(), enforce: true
  end
end

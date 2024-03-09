defmodule LittleRetro.Retros.Commands.AddUser do
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :email, String.t(), enforce: true
  end
end

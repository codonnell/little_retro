defmodule LittleRetro.Retros.Events.UserAddedByEmail do
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :email, String.t(), enforce: true
  end
end

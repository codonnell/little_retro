defmodule LittleRetro.Retros.Events.UserRemovedByEmail do
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :email, String.t(), enforce: true
  end
end

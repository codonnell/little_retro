defmodule LittleRetro.Retros.Events.RetroCreated do
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :moderator_id, Integer.t(), enforce: true
  end
end

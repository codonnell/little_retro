defmodule LittleRetro.Retros.Events.CardCreated do
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :retro_id, String.t(), enforce: true
    field :column_id, integer(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

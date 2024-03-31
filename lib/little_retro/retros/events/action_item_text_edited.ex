defmodule LittleRetro.Retros.Events.ActionItemTextEdited do
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :text, String.t(), enforce: true
    field :retro_id, String.t(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

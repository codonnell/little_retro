defmodule LittleRetro.Retros.Aggregates.Retro.ActionItem do
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :text, String.t(), enforce: true
    field :author_id, integer(), enforce: true
  end
end

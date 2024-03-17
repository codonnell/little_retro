defmodule LittleRetro.Retros.Aggregates.Retro.Column do
  use TypedStruct

  typedstruct do
    field :id, integer(), enforce: true
    field :label, String.t(), enforce: true
    field :cards, [integer()], enforce: true, default: []
  end
end

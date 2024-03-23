defmodule LittleRetro.Retros.Commands.ChangePhase do
  alias LittleRetro.Retros.Aggregates.Retro
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :to, Retro.phase(), enforce: true
    field :user_id, integer(), enforce: true
  end
end

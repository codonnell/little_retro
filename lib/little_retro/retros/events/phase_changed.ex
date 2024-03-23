defmodule LittleRetro.Retros.Events.PhaseChanged do
  alias LittleRetro.Retros.Aggregates.Retro
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :from, Retro.phase(), enforce: true
    field :to, Retro.phase(), enforce: true
    field :user_id, integer(), enforce: true
  end
end

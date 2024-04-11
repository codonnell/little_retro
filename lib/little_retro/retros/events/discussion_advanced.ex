defmodule LittleRetro.Retros.Events.DiscussionAdvanced do
  alias LittleRetro.Retros.Aggregates.Retro.Card
  @derive Jason.Encoder
  use TypedStruct

  typedstruct do
    field :to, Card.id(), enforce: true
    field :retro_id, String.t(), enforce: true
    field :user_id, integer(), enforce: true
  end
end

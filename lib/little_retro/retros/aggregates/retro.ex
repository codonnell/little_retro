defmodule LittleRetro.Retros.Aggregates.Retro do
  alias LittleRetro.Retros.Events.RetroCreated
  alias LittleRetro.Retros.Commands.CreateRetro
  use TypedStruct

  typedstruct do
    field :id, String.t()
    field :moderator_id, Integer.t()
  end

  def execute(%__MODULE__{id: nil, moderator_id: nil}, %CreateRetro{
        id: id,
        moderator_id: moderator_id
      })
      when not is_nil(id) and not is_nil(moderator_id) do
    %RetroCreated{id: id, moderator_id: moderator_id}
  end

  def execute(%__MODULE__{id: nil, moderator_id: nil}, %CreateRetro{}) do
    {:error, :missing_required_field}
  end

  def execute(%__MODULE__{}, %CreateRetro{}) do
    {:error, :retro_already_created}
  end

  def apply(%__MODULE__{}, %RetroCreated{id: id, moderator_id: moderator_id}) do
    %__MODULE__{id: id, moderator_id: moderator_id}
  end
end

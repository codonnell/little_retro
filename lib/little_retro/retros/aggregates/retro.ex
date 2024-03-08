defmodule LittleRetro.Retros.Aggregates.Retro do
  alias LittleRetro.Retros.Events.RetroCreated
  alias LittleRetro.Retros.Commands.CreateRetro
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :moderator_id, integer(), enforce: true
    field :columns, %{String.t() => %__MODULE__.Column{}}, enforce: true
    field :column_order, [String.t()], enforce: true
  end

  typedstruct module: Column do
    field :label, String.t(), enforce: true
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
    %__MODULE__{
      id: id,
      moderator_id: moderator_id,
      columns: %{
        "Start" => %__MODULE__.Column{label: "Start"},
        "Stop" => %__MODULE__.Column{label: "Stop"},
        "Continue" => %__MODULE__.Column{label: "Continue"}
      },
      column_order: ["Start", "Stop", "Continue"]
    }
  end
end

defmodule LittleRetro.Retros.Aggregates.Retro do
  alias LittleRetro.Retros.Events.UserRemovedByEmail
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Events.UserAddedByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Retros.Events.RetroCreated
  alias LittleRetro.Retros.Commands.CreateRetro
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :moderator_id, integer(), enforce: true
    field :columns, %{String.t() => %__MODULE__.Column{}}, enforce: true, default: %{}
    field :column_order, [String.t()], enforce: true, default: []
    field :user_emails, [String.t()], enforce: true, default: []
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

  def execute(%__MODULE__{id: nil}, _) do
    {:error, :retro_not_found}
  end

  def execute(%__MODULE__{}, %AddUserByEmail{email: email}) when is_nil(email) do
    {:error, :missing_email}
  end

  def execute(%__MODULE__{}, %AddUserByEmail{id: id, email: email}) do
    if email =~ ~r/\s+/ do
      {:error, :blank_email}
    else
      %UserAddedByEmail{id: id, email: email}
    end
  end

  def execute(%__MODULE__{}, %RemoveUserByEmail{email: email}) when is_nil(email) do
    {:error, :missing_email}
  end

  def execute(%__MODULE__{}, %RemoveUserByEmail{id: id, email: email}) do
    if email =~ ~r/\s+/ do
      {:error, :blank_email}
    else
      %UserRemovedByEmail{id: id, email: email}
    end
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
      column_order: ["Start", "Stop", "Continue"],
      user_emails: []
    }
  end

  def apply(retro = %__MODULE__{user_emails: user_emails}, %UserAddedByEmail{email: email}) do
    if email in user_emails do
      retro
    else
      %{retro | user_emails: [email | user_emails]}
    end
  end

  def apply(retro = %__MODULE__{user_emails: user_emails}, %UserRemovedByEmail{email: email}) do
    %{retro | user_emails: Enum.reject(user_emails, &(&1 == email))}
  end
end

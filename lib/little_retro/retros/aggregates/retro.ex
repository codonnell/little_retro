defmodule LittleRetro.Retros.Aggregates.Retro do
  alias LittleRetro.Retros.Events.CardDeleted
  alias LittleRetro.Retros.Commands.DeleteCardById
  alias LittleRetro.Retros.Events.CardTextEdited
  alias LittleRetro.Retros.Commands.EditCardText
  alias LittleRetro.Retros.Events.CardCreated
  alias LittleRetro.Retros.Commands.CreateCard
  alias LittleRetro.Retros.Aggregates.Retro.Card
  alias LittleRetro.Retros.Aggregates.Retro.Column
  alias LittleRetro.Retros.Events.UserRemovedByEmail
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Events.UserAddedByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Retros.Events.RetroCreated
  alias LittleRetro.Retros.Commands.CreateRetro
  use TypedStruct

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :moderator_id, integer(), enforce: true
    field :columns, %{integer() => %Column{}}, enforce: true, default: %{}
    field :column_order, [Column.id()], enforce: true, default: []
    field :user_emails, [String.t()], enforce: true, default: []
    field :cards, %{integer() => %Card{}}, enforce: true, default: %{}
    field :phase, :create_cards | :group_cards | :vote | :discussion, enforce: true
  end

  def execute(%__MODULE__{retro_id: nil, moderator_id: nil}, %CreateRetro{
        retro_id: retro_id,
        moderator_id: moderator_id
      })
      when not is_nil(retro_id) and not is_nil(moderator_id) do
    %RetroCreated{retro_id: retro_id, moderator_id: moderator_id}
  end

  def execute(%__MODULE__{retro_id: nil, moderator_id: nil}, %CreateRetro{}) do
    {:error, :missing_required_field}
  end

  def execute(%__MODULE__{}, %CreateRetro{}) do
    {:error, :retro_already_created}
  end

  def execute(%__MODULE__{retro_id: nil}, _) do
    {:error, :retro_not_found}
  end

  def execute(%__MODULE__{}, %AddUserByEmail{email: email}) when is_nil(email) do
    {:error, :missing_email}
  end

  def execute(%__MODULE__{}, %AddUserByEmail{retro_id: retro_id, email: email}) do
    if email =~ ~r/\s+/ do
      {:error, :blank_email}
    else
      %UserAddedByEmail{retro_id: retro_id, email: email}
    end
  end

  def execute(%__MODULE__{}, %RemoveUserByEmail{email: email}) when is_nil(email) do
    {:error, :missing_email}
  end

  def execute(%__MODULE__{}, %RemoveUserByEmail{retro_id: retro_id, email: email}) do
    if email =~ ~r/\s+/ do
      {:error, :blank_email}
    else
      %UserRemovedByEmail{retro_id: retro_id, email: email}
    end
  end

  def execute(%__MODULE__{phase: :create_cards, columns: columns, cards: cards}, %CreateCard{
        retro_id: retro_id,
        column_id: column_id,
        author_id: author_id
      }) do
    if not Map.has_key?(columns, column_id) do
      {:error, :column_not_found}
    else
      card_id = (cards |> Map.keys() |> Enum.max(&>=/2, fn -> -1 end)) + 1
      %CardCreated{retro_id: retro_id, column_id: column_id, author_id: author_id, id: card_id}
    end
  end

  def execute(%__MODULE__{}, %CreateCard{}) do
    {:error, :incorrect_phase}
  end

  def execute(%__MODULE__{moderator_id: moderator_id, cards: cards}, %EditCardText{
        id: id,
        text: text,
        author_id: author_id,
        retro_id: retro_id
      }) do
    cond do
      not Map.has_key?(cards, id) -> {:error, :card_not_found}
      author_id != moderator_id and author_id != cards[id].author_id -> {:error, :unauthorized}
      String.length(text) > 255 -> {:error, :card_text_too_long}
      true -> %CardTextEdited{id: id, author_id: author_id, text: text, retro_id: retro_id}
    end
  end

  def execute(retro = %__MODULE__{}, %DeleteCardById{
        retro_id: retro_id,
        id: id,
        author_id: author_id,
        column_id: column_id
      }) do
    card = Map.get(retro.cards, id)

    cond do
      is_nil(card) ->
        {:error, :card_not_found}

      card.author_id != author_id and retro.moderator_id != author_id ->
        {:error, :unauthorized}

      not Map.has_key?(retro.columns, column_id) ->
        {:error, :column_not_found}

      id not in retro.columns[column_id].cards ->
        {:error, :card_not_in_column}

      true ->
        %CardDeleted{id: id, author_id: author_id, column_id: column_id, retro_id: retro_id}
    end
  end

  def execute(%__MODULE__{}, _command) do
    {:error, :unrecognized_command}
  end

  def apply(%__MODULE__{}, %RetroCreated{retro_id: retro_id, moderator_id: moderator_id}) do
    %__MODULE__{
      retro_id: retro_id,
      phase: :create_cards,
      moderator_id: moderator_id,
      columns: %{
        0 => %Column{id: 0, label: "Start", cards: []},
        1 => %Column{id: 1, label: "Stop", cards: []},
        2 => %Column{id: 2, label: "Continue", cards: []}
      },
      column_order: [0, 1, 2],
      user_emails: [],
      cards: %{}
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

  def apply(retro = %__MODULE__{columns: columns, cards: cards}, %CardCreated{
        id: id,
        author_id: author_id,
        column_id: column_id
      }) do
    columns =
      update_in(columns, [Access.key!(column_id), Access.key!(:cards)], fn cards ->
        [id | cards]
      end)

    card = %Card{id: id, author_id: author_id, text: ""}

    %{retro | columns: columns, cards: Map.put(cards, id, card)}
  end

  def apply(retro = %__MODULE__{}, %CardTextEdited{id: id, text: text}) do
    put_in(retro, [Access.key!(:cards), Access.key!(id), Access.key!(:text)], text)
  end

  def apply(retro = %__MODULE__{}, %CardDeleted{id: id, column_id: column_id}) do
    retro
    |> update_in([Access.key!(:cards)], fn cards -> Map.delete(cards, id) end)
    |> update_in([Access.key!(:columns), Access.key!(column_id), Access.key!(:cards)], fn cards ->
      Enum.filter(cards, fn card_id -> card_id != id end)
    end)
  end
end

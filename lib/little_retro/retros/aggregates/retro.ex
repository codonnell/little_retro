defmodule LittleRetro.Retros.Aggregates.Retro do
  alias LittleRetro.Retros.Events.CardRemovedFromGroup
  alias LittleRetro.Retros.Commands.RemoveCardFromGroup
  alias LittleRetro.Retros.Events.CardsGrouped
  alias LittleRetro.Retros.Commands.GroupCards
  alias LittleRetro.Retros.Events.PhaseChanged
  alias LittleRetro.Retros.Commands.ChangePhase
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

  @type phase :: :create_cards | :group_cards | :vote | :discussion | :complete

  typedstruct do
    field :retro_id, String.t(), enforce: true
    field :moderator_id, integer(), enforce: true
    field :columns, %{Column.id() => %Column{}}, enforce: true, default: %{}
    field :column_order, [Column.id()], enforce: true, default: []
    field :user_emails, [String.t()], enforce: true, default: []
    field :cards, %{Card.id() => %Card{}}, enforce: true, default: %{}
    field :groups, %{Card.id() => %{cards: [Card.id()]}}, enforce: true, default: %{}
    field :grouped_onto, %{Card.id() => Card.id()}, enforce: true, default: []
    field :phase, phase(), enforce: true
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

  def execute(
        %__MODULE__{phase: :create_cards, moderator_id: moderator_id, cards: cards},
        %EditCardText{
          id: id,
          text: text,
          author_id: author_id,
          retro_id: retro_id
        }
      ) do
    cond do
      not Map.has_key?(cards, id) -> {:error, :card_not_found}
      author_id != moderator_id and author_id != cards[id].author_id -> {:error, :unauthorized}
      String.length(text) > 255 -> {:error, :card_text_too_long}
      true -> %CardTextEdited{id: id, author_id: author_id, text: text, retro_id: retro_id}
    end
  end

  def execute(%__MODULE__{}, %EditCardText{}) do
    {:error, :incorrect_phase}
  end

  def execute(retro = %__MODULE__{phase: :create_cards}, %DeleteCardById{
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

  def execute(%__MODULE__{}, %DeleteCardById{}) do
    {:error, :incorrect_phase}
  end

  def execute(retro = %__MODULE__{phase: from}, %ChangePhase{
        retro_id: retro_id,
        to: to,
        user_id: user_id
      }) do
    if retro.moderator_id == user_id do
      %PhaseChanged{retro_id: retro_id, from: from, to: to, user_id: user_id}
    else
      {:error, :unauthorized}
    end
  end

  def execute(
        retro = %__MODULE__{phase: :group_cards},
        cmd = %GroupCards{card_id: card_id, onto: onto}
      ) do
    cond do
      not (Map.has_key?(retro.cards, card_id) and Map.has_key?(retro.cards, onto)) ->
        {:error, :card_not_found}

      Map.get(retro.grouped_onto, onto, :missing) not in [onto, :missing] ->
        {:error, :invalid_input}

      Map.has_key?(retro.groups, onto) and card_id in retro.groups[onto][:cards] ->
        {:error, :invalid_input}

      true ->
        %CardsGrouped{retro_id: cmd.retro_id, user_id: cmd.user_id, card_id: card_id, onto: onto}
    end
  end

  def execute(%__MODULE__{}, %GroupCards{}) do
    {:error, :incorrect_phase}
  end

  def execute(
        retro = %__MODULE__{phase: :group_cards},
        cmd = %RemoveCardFromGroup{card_id: card_id}
      ) do
    cond do
      not Map.has_key?(retro.cards, card_id) ->
        {:error, :card_not_found}

      not Map.has_key?(retro.grouped_onto, card_id) ->
        {:error, :invalid_input}

      true ->
        %CardRemovedFromGroup{retro_id: cmd.retro_id, user_id: cmd.user_id, card_id: card_id}
    end
  end

  def execute(%__MODULE__{}, %RemoveCardFromGroup{}) do
    {:error, :incorrect_phase}
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
      cards: %{},
      groups: %{},
      grouped_onto: %{}
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

  def apply(retro = %__MODULE__{}, %PhaseChanged{to: to}) do
    # We may get events from memory, in which case phase is an atom, or from the database, in which case phase is a string
    to =
      if is_atom(to) do
        to
      else
        String.to_existing_atom(to)
      end

    %__MODULE__{retro | phase: to}
  end

  def apply(retro = %__MODULE__{}, %CardsGrouped{card_id: card_id, onto: onto}) do
    retro =
      if Map.has_key?(retro.grouped_onto, card_id) do
        remove_from_group(retro, card_id)
      else
        retro
      end

    add_to_group(retro, card_id, onto)
  end

  def apply(retro = %__MODULE__{}, %CardRemovedFromGroup{card_id: card_id}) do
    remove_from_group(retro, card_id)
  end

  defp remove_from_group(retro = %__MODULE__{}, card_id) do
    if Map.has_key?(retro.groups, card_id) do
      group = retro.groups[card_id]

      case Enum.reverse(group[:cards]) do
        [^card_id, other_card_id] ->
          %__MODULE__{
            retro
            | groups: Map.delete(retro.groups, card_id),
              grouped_onto: retro.grouped_onto |> Map.delete(card_id) |> Map.delete(other_card_id)
          }

        [^card_id, new_bottom | rest] ->
          %__MODULE__{
            retro
            | groups:
                retro.groups
                |> Map.delete(card_id)
                |> Map.put(new_bottom, Map.put(group, :cards, Enum.reverse([new_bottom | rest]))),
              grouped_onto:
                Enum.reduce(rest, retro.grouped_onto, fn id, grouped_onto ->
                  Map.put(grouped_onto, id, new_bottom)
                end)
                |> Map.put(new_bottom, new_bottom)
                |> Map.delete(card_id)
          }
      end
    else
      onto = Map.get(retro.grouped_onto, card_id)

      retro = %__MODULE__{
        retro
        | groups:
            update_in(retro.groups, [Access.key!(onto), Access.key!(:cards)], fn cards ->
              Enum.reject(cards, &(&1 == card_id))
            end),
          grouped_onto: Map.delete(retro.grouped_onto, card_id)
      }

      if 1 == Enum.count(retro.groups[onto][:cards]) do
        %__MODULE__{
          retro
          | groups: Map.delete(retro.groups, onto),
            grouped_onto: Map.delete(retro.grouped_onto, onto)
        }
      else
        retro
      end
    end
  end

  defp add_to_group(retro = %__MODULE__{}, card_id, onto) do
    retro
    |> update_in([Access.key!(:groups), Access.key(onto)], fn
      nil ->
        %{cards: [card_id, onto]}

      group ->
        Map.update!(group, :cards, fn cards -> [card_id | cards] end)
    end)
    |> put_in([Access.key!(:grouped_onto), Access.key(onto)], onto)
    |> put_in([Access.key!(:grouped_onto), Access.key(card_id)], onto)
  end
end

defmodule LittleRetro.Retros do
  alias LittleRetro.Retros.Commands.CreateActionItem
  alias LittleRetro.Retros.Commands.RemoveVoteFromCard
  alias LittleRetro.Retros.Commands.VoteForCard
  alias LittleRetro.Retros.Commands.RemoveCardFromGroup
  alias LittleRetro.Retros.Commands.GroupCards
  alias LittleRetro.Retros.Aggregates.Retro.Card
  alias LittleRetro.Retros.Aggregates.Retro.Column
  alias LittleRetro.Retros.Commands.ChangePhase
  alias LittleRetro.Retros.Commands.DeleteCardById
  alias LittleRetro.Retros.Commands.EditCardText
  alias LittleRetro.Retros.Commands.CreateCard
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias Commanded.UUID
  alias LittleRetro.Retros.Commands.CreateRetro
  alias LittleRetro.CommandedApplication

  @phases [
    %{
      id: :create_cards,
      label: "Create"
    },
    %{
      id: :group_cards,
      label: "Group"
    },
    %{
      id: :vote,
      label: "Vote"
    },
    %{
      id: :discussion,
      label: "Discuss"
    }
  ]

  @spec get(retro_id :: String.t(), timeout :: integer()) :: Retro.t()
  def get(retro_id, timeout \\ 5000) do
    Commanded.aggregate_state(CommandedApplication, Retro, retro_id, timeout)
  end

  @type phase :: %{id: Retro.phase(), label: String.t()}

  @spec phases() :: [phase()]
  def phases() do
    @phases
  end

  def create_retro(moderator_id) do
    case Accounts.get_user(moderator_id) do
      %User{} ->
        retro_id = UUID.uuid4()

        CommandedApplication.dispatch(%CreateRetro{retro_id: retro_id, moderator_id: moderator_id})

        {:ok, retro_id}

      nil ->
        {:error, :moderator_not_found}
    end
  end

  def add_user(retro_id, email) do
    case CommandedApplication.dispatch(%AddUserByEmail{retro_id: retro_id, email: email}) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  def remove_user(retro_id, email) do
    case CommandedApplication.dispatch(%RemoveUserByEmail{retro_id: retro_id, email: email}) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec create_card(retro_id :: String.t(), %{author_id: integer(), column_id: Column.id()}) ::
          :ok | {:error, atom()}

  def create_card(retro_id, %{author_id: author_id, column_id: column_id}) do
    case CommandedApplication.dispatch(%CreateCard{
           retro_id: retro_id,
           author_id: author_id,
           column_id: column_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  def edit_card_text(retro_id, %{id: id, author_id: author_id, text: text}) do
    case CommandedApplication.dispatch(%EditCardText{
           retro_id: retro_id,
           id: id,
           author_id: author_id,
           text: text
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec delete_card_by_id(retro_id :: String.t(), %{
          id: integer(),
          author_id: integer(),
          column_id: Column.id()
        }) :: :ok | {:error, atom()}

  def delete_card_by_id(retro_id, %{id: id, author_id: author_id, column_id: column_id}) do
    case CommandedApplication.dispatch(%DeleteCardById{
           id: id,
           author_id: author_id,
           column_id: column_id,
           retro_id: retro_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec change_phase(retro_id :: String.t(), %{phase: Retro.phase(), user_id: integer()}) ::
          :ok | {:error, atom()}

  def change_phase(retro_id, %{phase: phase, user_id: user_id}) do
    case CommandedApplication.dispatch(%ChangePhase{
           retro_id: retro_id,
           to: phase,
           user_id: user_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec group_cards(retro_id :: String.t(), %{
          user_id: integer(),
          card_id: Card.id(),
          onto: Card.id()
        }) :: :ok | {:error, atom()}

  def group_cards(retro_id, %{user_id: user_id, card_id: card_id, onto: onto}) do
    case CommandedApplication.dispatch(%GroupCards{
           retro_id: retro_id,
           user_id: user_id,
           card_id: card_id,
           onto: onto
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec remove_card_from_group(retro_id :: String.t(), %{user_id: integer(), card_id: Card.id()}) ::
          :ok | {:error, atom()}

  def remove_card_from_group(retro_id, %{user_id: user_id, card_id: card_id}) do
    case CommandedApplication.dispatch(%RemoveCardFromGroup{
           retro_id: retro_id,
           user_id: user_id,
           card_id: card_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec vote_for_card(retro_id :: String.t(), %{user_id: integer(), card_id: Card.id()}) ::
          :ok | {:error, atom()}

  def vote_for_card(retro_id, %{user_id: user_id, card_id: card_id}) do
    case CommandedApplication.dispatch(%VoteForCard{
           retro_id: retro_id,
           user_id: user_id,
           card_id: card_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec remove_vote_from_card(retro_id :: String.t(), %{user_id: integer(), card_id: Card.id()}) ::
          :ok | {:error, atom()}

  def remove_vote_from_card(retro_id, %{user_id: user_id, card_id: card_id}) do
    case CommandedApplication.dispatch(%RemoveVoteFromCard{
           retro_id: retro_id,
           user_id: user_id,
           card_id: card_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  @spec create_action_item(retro_id :: String.t(), %{author_id: integer()}) ::
          :ok | {:error, atom()}

  def create_action_item(retro_id, %{author_id: author_id}) do
    case CommandedApplication.dispatch(%CreateActionItem{
           retro_id: retro_id,
           author_id: author_id
         }) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end
end

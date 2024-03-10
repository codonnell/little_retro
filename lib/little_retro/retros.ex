defmodule LittleRetro.Retros do
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias Commanded.UUID
  alias LittleRetro.Retros.Commands.CreateRetro
  alias LittleRetro.CommandedApplication

  def get(id, timeout \\ 5000) do
    Commanded.aggregate_state(CommandedApplication, Retro, id, timeout)
  end

  def create_retro(moderator_id) do
    case Accounts.get_user(moderator_id) do
      %User{} ->
        id = UUID.uuid4()
        CommandedApplication.dispatch(%CreateRetro{id: id, moderator_id: moderator_id})
        {:ok, id}

      nil ->
        {:error, :moderator_not_found}
    end
  end

  def add_user(id, email) do
    case CommandedApplication.dispatch(%AddUserByEmail{id: id, email: email}) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end

  def remove_user(id, email) do
    case CommandedApplication.dispatch(%RemoveUserByEmail{id: id, email: email}) do
      {:error, err} -> {:error, err}
      _ -> :ok
    end
  end
end

defmodule LittleRetro.Retros do
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias Commanded.UUID
  alias LittleRetro.Retros.Commands.CreateRetro
  alias LittleRetro.CommandedApplication

  def get(retro_id, timeout \\ 5000) do
    Commanded.aggregate_state(CommandedApplication, Retro, retro_id, timeout)
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
end

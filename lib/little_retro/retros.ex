defmodule LittleRetro.Retros do
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias Commanded.UUID
  alias LittleRetro.Retros.Commands.CreateRetro
  alias LittleRetro.CommandedApplication

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
end

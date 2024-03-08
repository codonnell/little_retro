defmodule LittleRetro.RetrosTest do
  alias LittleRetro.CommandedApplication
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Accounts.User
  alias LittleRetro.Accounts
  alias LittleRetro.Retros

  use LittleRetro.DataCase

  import LittleRetro.AccountsFixtures

  describe "create_retro/1" do
    test "returns error when moderator doesn't exist" do
      assert {:error, :moderator_not_found} == Retros.create_retro(-1)
    end

    test "creates a retro when moderator does exist" do
      %User{id: moderator_id} = user_fixture()
      assert {:ok, id} = Retros.create_retro(moderator_id)

      assert %Retro{id: id, moderator_id: moderator_id} =
               Commanded.aggregate_state(CommandedApplication, Retro, id)
    end
  end
end

defmodule LittleRetro.RetrosTest do
  alias LittleRetro.CommandedApplication
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Accounts.User
  alias LittleRetro.Accounts
  alias LittleRetro.Retros

  use LittleRetro.DataCase

  import LittleRetro.AccountsFixtures
  import LittleRetro.RetrosFixtures

  describe "create_retro/1" do
    test "returns error when moderator doesn't exist" do
      assert {:error, :moderator_not_found} == Retros.create_retro(-1)
    end

    test "creates a retro when moderator does exist" do
      %User{id: moderator_id} = user_fixture()
      assert {:ok, id} = Retros.create_retro(moderator_id)

      assert %Retro{id: ^id, moderator_id: ^moderator_id} = Retros.get(id)
    end
  end

  describe "add_user/1" do
    test "returns error on retro not found" do
      assert {:error, :retro_not_found} ==
               Retros.add_user(Commanded.UUID.uuid4(), "test@example.com")
    end

    test "returns error on blank email" do
      id = retro_fixture()
      assert {:error, :blank_email} == Retros.add_user(id, "   ")
    end

    test "returns error on missing email" do
      id = retro_fixture()
      assert {:error, :missing_email} == Retros.add_user(id, nil)
    end

    test "adds user with proper email" do
      id = retro_fixture()
      assert :ok == Retros.add_user(id, "test@example.com")

      assert %Retro{user_emails: ["test@example.com"]} = Retros.get(id)
    end

    test "idempotently adds the same email twice" do
      id = retro_fixture()
      assert :ok == Retros.add_user(id, "test@example.com")
      assert :ok == Retros.add_user(id, "test@example.com")

      assert %Retro{user_emails: ["test@example.com"]} = Retros.get(id)
    end
  end

  describe "remove_user/1" do
    setup do
      id = retro_fixture()
      Retros.add_user(id, "test@example.com")
      %{id: id, email: "test@example.com"}
    end

    test "returns error on retro not found" do
      assert {:error, :retro_not_found} ==
               Retros.remove_user(Commanded.UUID.uuid4(), "test@example.com")
    end

    test "returns error on blank email", %{id: id} do
      assert {:error, :blank_email} == Retros.remove_user(id, "   ")
    end

    test "returns error on missing email", %{id: id} do
      assert {:error, :missing_email} == Retros.remove_user(id, nil)
    end

    test "removes user with proper email", %{id: id, email: email} do
      assert :ok == Retros.remove_user(id, email)

      assert %Retro{user_emails: []} = Retros.get(id)
    end

    test "idempotently removes the same email twice", %{id: id, email: email} do
      assert :ok == Retros.remove_user(id, email)
      assert :ok == Retros.remove_user(id, email)

      assert %Retro{user_emails: []} = Retros.get(id)
    end
  end
end

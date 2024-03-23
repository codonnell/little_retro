defmodule LittleRetro.RetrosTest do
  alias LittleRetro.Retros.Aggregates.Retro.Card
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Accounts.User
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
      assert {:ok, retro_id} = Retros.create_retro(moderator_id)

      assert %Retro{retro_id: ^retro_id, moderator_id: ^moderator_id} = Retros.get(retro_id)
    end
  end

  describe "add_user/1" do
    test "returns error on retro not found" do
      assert {:error, :retro_not_found} ==
               Retros.add_user(Commanded.UUID.uuid4(), "test@example.com")
    end

    test "returns error on blank email" do
      retro_id = retro_fixture()
      assert {:error, :blank_email} == Retros.add_user(retro_id, "   ")
    end

    test "returns error on missing email" do
      retro_id = retro_fixture()
      assert {:error, :missing_email} == Retros.add_user(retro_id, nil)
    end

    test "adds user with proper email" do
      retro_id = retro_fixture()
      assert :ok == Retros.add_user(retro_id, "test@example.com")

      assert %Retro{user_emails: ["test@example.com"]} = Retros.get(retro_id)
    end

    test "idempotently adds the same email twice" do
      retro_id = retro_fixture()
      assert :ok == Retros.add_user(retro_id, "test@example.com")
      assert :ok == Retros.add_user(retro_id, "test@example.com")

      assert %Retro{user_emails: ["test@example.com"]} = Retros.get(retro_id)
    end
  end

  describe "remove_user/1" do
    setup do
      retro_id = retro_fixture()
      Retros.add_user(retro_id, "test@example.com")
      %{retro_id: retro_id, email: "test@example.com"}
    end

    test "returns error on retro not found" do
      assert {:error, :retro_not_found} ==
               Retros.remove_user(Commanded.UUID.uuid4(), "test@example.com")
    end

    test "returns error on blank email", %{retro_id: retro_id} do
      assert {:error, :blank_email} == Retros.remove_user(retro_id, "   ")
    end

    test "returns error on missing email", %{retro_id: retro_id} do
      assert {:error, :missing_email} == Retros.remove_user(retro_id, nil)
    end

    test "removes user with proper email", %{retro_id: retro_id, email: email} do
      assert :ok == Retros.remove_user(retro_id, email)

      assert %Retro{user_emails: []} = Retros.get(retro_id)
    end

    test "idempotently removes the same email twice", %{retro_id: retro_id, email: email} do
      assert :ok == Retros.remove_user(retro_id, email)
      assert :ok == Retros.remove_user(retro_id, email)

      assert %Retro{user_emails: []} = Retros.get(retro_id)
    end
  end

  describe "create_card/2" do
    setup do
      retro_id = retro_fixture()
      %{retro_id: retro_id}
    end

    test "creates a card with empty text", %{retro_id: retro_id} do
      Retros.create_card(retro_id, %{author_id: 0, column_id: 0})
      retro = Retros.get(retro_id)
      assert retro.cards[0] == %Card{id: 0, author_id: 0, text: ""}
      assert retro.columns[0].cards == [0]
    end

    test "doesn't create a card in a non-existent column", %{retro_id: retro_id} do
      assert {:error, _} = Retros.create_card(retro_id, %{author_id: 0, column_id: -1})
    end
  end

  describe "edit_card_text/2" do
    setup do
      user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      %{user: user, retro_id: retro_id}
    end

    test "edits a card successfully", %{retro_id: retro_id, user: user} do
      Retros.edit_card_text(retro_id, %{id: 0, text: "Hello World", author_id: user.id})
      assert Retros.get(retro_id).cards[0].text == "Hello World"
    end

    test "non-author cannot edit card", %{retro_id: retro_id} do
      assert {:error, :unauthorized} ==
               Retros.edit_card_text(retro_id, %{author_id: -1, text: "Hello World", id: 0})
    end

    test "cannot edit nonexistent card", %{retro_id: retro_id, user: user} do
      assert {:error, :card_not_found} ==
               Retros.edit_card_text(retro_id, %{id: -1, author_id: user.id, text: "Hello World"})
    end

    test "cannot make text more than 255 characters", %{retro_id: retro_id, user: user} do
      text = String.duplicate("a", 256)

      assert {:error, :card_text_too_long} ==
               Retros.edit_card_text(retro_id, %{id: 0, text: text, author_id: user.id})
    end
  end

  describe "delete_card_by_id/2" do
    setup do
      user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      %{user: user, retro_id: retro_id}
    end

    test "deletes a card successfully", %{retro_id: retro_id, user: user} do
      assert :ok == Retros.delete_card_by_id(retro_id, %{id: 0, author_id: user.id, column_id: 0})
      refute Map.has_key?(Retros.get(retro_id).cards, 0)
    end

    test "cannot delete nonexistent card", %{retro_id: retro_id, user: user} do
      assert {:error, :card_not_found} ==
               Retros.delete_card_by_id(retro_id, %{id: 1, author_id: user.id, column_id: 0})
    end

    test "non-author cannot edit card", %{retro_id: retro_id} do
      assert {:error, :unauthorized} ==
               Retros.delete_card_by_id(retro_id, %{id: 0, author_id: -1, column_id: 0})
    end

    test "cannot delete card with nonexistent column", %{retro_id: retro_id, user: user} do
      assert {:error, :column_not_found} ==
               Retros.delete_card_by_id(retro_id, %{id: 0, author_id: user.id, column_id: -1})
    end

    test "cannot delete card with incorrect column", %{retro_id: retro_id, user: user} do
      assert {:error, :card_not_in_column} ==
               Retros.delete_card_by_id(retro_id, %{id: 0, author_id: user.id, column_id: 1})
    end
end

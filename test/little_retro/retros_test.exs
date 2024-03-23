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
    setup do
      retro_fixture()
    end

    test "returns error on retro not found" do
      assert {:error, :retro_not_found} ==
               Retros.add_user(Commanded.UUID.uuid4(), "test@example.com")
    end

    test "returns error on blank email", %{retro_id: retro_id} do
      assert {:error, :blank_email} == Retros.add_user(retro_id, "   ")
    end

    test "returns error on missing email", %{retro_id: retro_id} do
      assert {:error, :missing_email} == Retros.add_user(retro_id, nil)
    end

    test "adds user with proper email", %{retro_id: retro_id} do
      assert :ok == Retros.add_user(retro_id, "test@example.com")

      assert %Retro{user_emails: ["test@example.com"]} = Retros.get(retro_id)
    end

    test "idempotently adds the same email twice", %{retro_id: retro_id} do
      assert :ok == Retros.add_user(retro_id, "test@example.com")
      assert :ok == Retros.add_user(retro_id, "test@example.com")

      assert %Retro{user_emails: ["test@example.com"]} = Retros.get(retro_id)
    end
  end

  describe "remove_user/1" do
    setup do
      %{retro_id: retro_id} = retro_fixture()
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
      retro_fixture()
    end

    test "creates a card with empty text", %{retro_id: retro_id} do
      assert :ok == Retros.create_card(retro_id, %{author_id: 0, column_id: 0})
      retro = Retros.get(retro_id)
      assert retro.cards[0] == %Card{id: 0, author_id: 0, text: ""}
      assert retro.columns[0].cards == [0]
    end

    test "doesn't create a card in a non-existent column", %{retro_id: retro_id} do
      assert {:error, _} = Retros.create_card(retro_id, %{author_id: 0, column_id: -1})
    end

    test "doesn't create a card in the wrong phase", %{retro_id: retro_id, user: user} do
      Retros.change_phase(retro_id, %{phase: :group_cards, user_id: user.id})
      assert {:error, _} = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
    end
  end

  describe "edit_card_text/2" do
    setup do
      %{retro_id: retro_id, user: user} = retro_fixture()
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
      %{retro_id: retro_id, user: user} = retro_fixture()
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

  describe "change_phase/2" do
    setup do
      retro_fixture()
    end

    test "can change phase from create cards to group cards", %{retro_id: retro_id, user: user} do
      assert :ok == Retros.change_phase(retro_id, %{phase: :group_cards, user_id: user.id})
      assert %Retro{phase: :group_cards} = Retros.get(retro_id)
    end
  end

  describe "group_cards/2" do
    setup do
      %{retro_id: retro_id, user: user} = retro_fixture()
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      Retros.change_phase(retro_id, %{phase: :group_cards, user_id: user.id})

      %{
        retro_id: retro_id,
        user: user,
        group: fn card_id, onto ->
          Retros.group_cards(retro_id, %{user_id: user.id, card_id: card_id, onto: onto})
        end
      }
    end

    test "can group cards that are both not already grouped", %{retro_id: retro_id, group: group} do
      assert :ok == group.(1, 0)
      retro = Retros.get(retro_id)
      assert 0 == retro.grouped_onto[0]
      assert 0 == retro.grouped_onto[1]
      assert [1, 0] = retro.groups[0][:cards]
    end

    test "can add to an existing group", %{retro_id: retro_id, group: group} do
      :ok = group.(1, 0)
      assert :ok == group.(2, 0)
      retro = Retros.get(retro_id)
      assert 0 == retro.grouped_onto[2]
      assert [2, 1, 0] == retro.groups[0][:cards]
    end

    test "can disband an existing group", %{retro_id: retro_id, group: group} do
      :ok = group.(1, 0)
      assert :ok == group.(0, 2)
      retro = Retros.get(retro_id)
      refute Map.has_key?(retro.grouped_onto, 1)
      assert 2 == retro.grouped_onto[2]
      assert 2 == retro.grouped_onto[0]
      refute Map.has_key?(retro.groups, 0)
      assert [0, 2] == retro.groups[2][:cards]
    end

    test "can remove from bottom of an existing group", %{retro_id: retro_id, group: group} do
      :ok = group.(1, 0)
      :ok = group.(2, 0)
      assert :ok == group.(0, 3)
      retro = Retros.get(retro_id)
      assert 1 == retro.grouped_onto[1]
      assert 1 == retro.grouped_onto[2]
      assert 3 == retro.grouped_onto[0]
      assert 3 == retro.grouped_onto[3]
      assert [2, 1] == retro.groups[1][:cards]
      assert [0, 3] == retro.groups[3][:cards]
    end

    test "can remove from middle of an existing group", %{retro_id: retro_id, group: group} do
      :ok = group.(1, 0)
      :ok = group.(2, 0)
      assert :ok == group.(1, 3)
      retro = Retros.get(retro_id)
      assert 0 == retro.grouped_onto[0]
      assert 0 == retro.grouped_onto[2]
      assert 3 == retro.grouped_onto[1]
      assert 3 == retro.grouped_onto[3]
      assert [2, 0] == retro.groups[0][:cards]
      assert [1, 3] == retro.groups[3][:cards]
    end

    test "cannot group onto a nonexistent card", %{group: group} do
      assert {:error, :card_not_found} == group.(0, -1)
    end

    test "cannot group a nonexistent card", %{group: group} do
      assert {:error, :card_not_found} == group.(-1, 0)
    end

    test "cannot group onto a middle card", %{group: group} do
      :ok = group.(1, 0)
      assert {:error, _} = group.(2, 1)
    end

    test "cannot group a card onto the bottom of its own group", %{group: group} do
      :ok = group.(1, 0)
      assert {:error, _} = group.(1, 0)
    end

    test "cannot group a card onto the middle of its own group", %{group: group} do
      :ok = group.(1, 0)
      :ok = group.(2, 0)
      assert {:error, _} = group.(2, 1)
    end

    # New case: grouping a bottom card into the group it's already in
    # New case: grouping a non-bottom card into the group it's already in
  end
end

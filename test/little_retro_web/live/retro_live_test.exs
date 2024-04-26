defmodule LittleRetroWeb.RetroLiveTest do
  alias Phoenix.PubSub
  alias LittleRetro.Retros
  use LittleRetroWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import LittleRetro.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "add user" do
    test "moderator can add user by email", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      email = "foo@example.com"

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/retros/#{retro_id}")

      view
      |> form(data_test_sel("user-email-form"))
      |> render_submit(%{user: %{email: email}})

      assert has_element?(
               view,
               data_test_sel("user-email-list-item-#{email}"),
               "foo@example.com"
             )
    end

    test "non-moderator cannot add user by email", %{conn: conn, user: user} do
      moderator = user_fixture()
      {:ok, retro_id} = Retros.create_retro(moderator.id)
      Retros.add_user(retro_id, user.email)
      email = "foo@example.com"

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/retros/#{retro_id}")

      assert view
             |> form(data_test_sel("user-email-form"))
             |> render_submit(%{user: %{email: email}}) =~
               "Only the moderator can add and remove users"
    end
  end

  describe "remove user" do
    test "moderator can remove user by email", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      email = "foo@example.com"
      Retros.add_user(retro_id, email)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/retros/#{retro_id}")

      view
      |> data_test("remove-user-email-#{email}")
      |> render_click()

      refute has_element?(view, data_test_sel("user-email-list-item-#{email}"))
    end

    test "non-moderator cannot remove user by email", %{conn: conn, user: user} do
      moderator = user_fixture()
      {:ok, retro_id} = Retros.create_retro(moderator.id)
      Retros.add_user(retro_id, user.email)
      email = "foo@example.com"
      Retros.add_user(retro_id, email)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/retros/#{retro_id}")

      assert view
             |> data_test("remove-user-email-#{email}")
             |> render_click() =~
               "Only the moderator can add and remove users"
    end
  end

  describe "create card" do
    test "authorized user can create a card", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/retros/#{retro_id}")

      view
      |> data_test("create-card-column-0")
      |> render_click()

      assert has_element?(view, data_test_sel("card-list-item-0"))
    end
  end

  describe "edit card" do
    test "other liveviews see card updates", %{conn: pub_conn, user: pub_user} do
      sub_conn = Phoenix.ConnTest.build_conn()
      sub_user = user_fixture()

      {:ok, retro_id} = Retros.create_retro(pub_user.id)
      Retros.add_user(retro_id, sub_user.email)
      Retros.create_card(retro_id, %{author_id: pub_user.id, column_id: 0})

      {:ok, pub_view, _html} =
        pub_conn |> log_in_user(pub_user) |> live(~p"/retros/#{retro_id}")

      {:ok, sub_view, _html} =
        sub_conn |> log_in_user(sub_user) |> live(~p"/retros/#{retro_id}")

      PubSub.subscribe(LittleRetro.PubSub, "retro:#{retro_id}")

      pub_view
      |> data_test("edit-card-form-0")
      |> render_change(%{"card-id" => 0, "text" => "Hello World"})

      wait_for(sub_view, :retro_updated)

      assert sub_view |> data_test("edit-card-textarea-0") |> render =~ "Hello World"
    end
  end

  describe "delete card" do
    test "card is removed from dom when deleted", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})

      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("delete-card-button-0") |> render_click()

      refute has_element?(view, "#edit-card-form-0")
    end
  end

  describe "change phase" do
    test "moderator can change phase", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("header-tab-group_cards") |> render_click()

      assert :group_cards == Retros.get(retro_id).phase
    end

    test "non-moderator cannot change phase", %{conn: conn, user: user} do
      moderator = user_fixture()
      {:ok, retro_id} = Retros.create_retro(moderator.id)
      Retros.add_user(retro_id, user.email)
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("header-tab-group_cards") |> render_click()

      assert view |> data_test("flash-group") |> render() =~
               "Only the moderator can change phase"

      assert :create_cards == Retros.get(retro_id).phase
    end
  end

  describe "vote for card" do
    test "can vote for single card", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :vote, user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("voteable-card-0") |> render_click()

      assert view |> has_element?(data_test_sel("vote-circle-0-0"))
    end

    test "can vote for group of cards", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :group_cards, user_id: user.id})
      :ok = Retros.group_cards(retro_id, %{user_id: user.id, card_id: 1, onto: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :vote, user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("voteable-card-0") |> render_click()

      assert view |> has_element?(data_test_sel("vote-circle-0-0"))
    end
  end

  describe "remove vote from card" do
    test "can remove vote from single card", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :vote, user_id: user.id})
      :ok = Retros.vote_for_card(retro_id, %{user_id: user.id, card_id: 0})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("vote-circle-0-0") |> render_click()

      refute view |> has_element?(data_test_sel("vote-circle-0-0"))
    end

    test "can remove vote from group of cards", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :group_cards, user_id: user.id})
      :ok = Retros.group_cards(retro_id, %{user_id: user.id, card_id: 1, onto: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :vote, user_id: user.id})
      :ok = Retros.vote_for_card(retro_id, %{user_id: user.id, card_id: 0})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("vote-circle-0-0") |> render_click()

      refute view |> has_element?(data_test_sel("vote-circle-0-0"))
    end
  end

  describe "vote counts" do
    test "vote counts are displayed", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)

      Enum.each(1..9, fn _ ->
        Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      end)

      :ok = Retros.change_phase(retro_id, %{phase: :vote, user_id: user.id})
      Retros.vote_for_card(retro_id, %{user_id: user.id, card_id: 0})
      Retros.vote_for_card(retro_id, %{user_id: user.id, card_id: 0})
      Retros.vote_for_card(retro_id, %{user_id: user.id, card_id: 1})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      assert has_element?(view, data_test_sel("discussion-circle-1"))
      assert has_element?(view, data_test_sel("discussion-circle-2"))
      refute has_element?(view, data_test_sel("discussion-circle-3"))

      view |> data_test("advance-discussion-button") |> render_click()

      assert has_element?(view, data_test_sel("discussion-circle-1"))
      refute has_element?(view, data_test_sel("discussion-circle-2"))

      view |> data_test("advance-discussion-button") |> render_click()

      refute has_element?(view, data_test_sel("discussion-card-1"))
    end
  end

  describe "advance discussion" do
    test "moderator can advance discussion", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("advance-discussion-button") |> render_click()

      assert has_element?(view, data_test_sel("discussion-card-1"))
    end

    test "non-moderator cannot advance discussion", %{conn: conn, user: user} do
      other_user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.add_user(retro_id, other_user.email)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(other_user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("advance-discussion-button") |> render_click()

      refute has_element?(view, data_test_sel("discussion-card-1"))
    end

    test "advance discussion is a no-op with no cards left", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      :ok = Retros.advance_discussion(retro_id, %{user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("advance-discussion-button") |> render_click()

      assert has_element?(view, data_test_sel("discussion-card-1"))
    end
  end

  describe "move discussion back" do
    test "moderator can move discussion back", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      :ok = Retros.advance_discussion(retro_id, %{user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("move-discussion-back-button") |> render_click()

      assert has_element?(view, data_test_sel("discussion-card-0"))
    end

    test "non-moderator cannot move discussion back", %{conn: conn, user: user} do
      other_user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.add_user(retro_id, other_user.email)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      :ok = Retros.advance_discussion(retro_id, %{user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(other_user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("move-discussion-back-button") |> render_click()

      assert has_element?(view, data_test_sel("discussion-card-1"))
    end

    test "move discussion back is a no-op with no cards left", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})
      :ok = Retros.change_phase(retro_id, %{phase: :discussion, user_id: user.id})
      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> data_test("move-discussion-back-button") |> render_click()

      assert has_element?(view, data_test_sel("discussion-card-0"))
    end
  end

  defp wait_for(view, msg) do
    # Ensure pubsub message has been broadcast
    assert_receive {^msg, _}

    # Sleep a very short time to increase probability pubsub message has been received by liveview process
    # Not my favorite, but seems ok for a small number of tests
    :timer.sleep(10)

    # Send message to liveview process to ensure liveview has processed pubsub message
    _ = :sys.get_state(view.pid)
  end

  defp data_test_sel(value) do
    "[data-test=\"#{value}\"]"
  end

  defp data_test(view, value) do
    element(view, data_test_sel(value))
  end
end

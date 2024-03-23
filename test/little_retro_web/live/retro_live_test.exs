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
      |> form("[data-test=user-email-form]")
      |> render_submit(%{user: %{email: email}})

      assert has_element?(
               view,
               "[data-test=\"user-email-list-item-#{email}\"]",
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
             |> form("[data-test=user-email-form]")
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
      |> element("[data-test=\"remove-user-email-#{email}\"]")
      |> render_click()

      refute has_element?(view, "[data-test=\"user-email-list-item-#{email}\"]")
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
             |> element("[data-test=\"remove-user-email-#{email}\"]")
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
      |> element("[data-test=create-card-column-0]")
      |> render_click()

      assert has_element?(view, "[data-test=card-list-item-0]")
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
      |> element("[data-test=\"edit-card-form-0\"]")
      |> render_change(%{"card-id" => 0, "text" => "Hello World"})

      wait_for(sub_view, :retro_updated)

      assert sub_view |> element("[data-test=edit-card-textarea-0]") |> render =~ "Hello World"
    end
  end

  describe "delete card" do
    test "card is removed from dom when deleted", %{conn: conn, user: user} do
      {:ok, retro_id} = Retros.create_retro(user.id)
      Retros.create_card(retro_id, %{author_id: user.id, column_id: 0})

      {:ok, view, _html} = conn |> log_in_user(user) |> live(~p"/retros/#{retro_id}")

      view |> element("[data-test=\"delete-card-button-0\"]") |> render_click()

      refute has_element?(view, "#edit-card-form-0")
    end
  end

  defp wait_for(view, msg) do
    # Ensure pubsub message has been broadcast
    assert_receive {^msg, _}
    # Send message to liveview process to ensure liveview has processed pubsub message
    _ = :sys.get_state(view.pid)
  end
end

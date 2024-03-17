defmodule LittleRetroWeb.CreateCardsLiveTest do
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
        |> live(~p"/retros/#{retro_id}/create_cards")

      PubSub.subscribe(LittleRetro.PubSub, "retro_users:#{retro_id}")

      view
      |> form("[data-test=user-email-form]")
      |> render_submit(%{user: %{email: email}})

      # Ensure pubsub message has been broadcast
      assert_receive {:user_added_by_email, ^email}
      # Send message to liveview process to ensure liveview has processed pubsub message
      _ = :sys.get_state(view.pid)

      assert render(view) =~ "foo@example.com"
    end

    test "non-moderator cannot add user by email", %{conn: conn, user: user} do
      moderator = user_fixture()
      {:ok, retro_id} = Retros.create_retro(moderator.id)
      Retros.add_user(retro_id, user.email)
      email = "foo@example.com"

      {:ok, view, _html} =
        conn
        |> log_in_user(user)
        |> live(~p"/retros/#{retro_id}/create_cards")

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
        |> live(~p"/retros/#{retro_id}/create_cards")

      PubSub.subscribe(LittleRetro.PubSub, "retro_users:#{retro_id}")

      view
      |> element("[data-test=\"remove-user-email-#{email}\"]")
      |> render_click()

      # Ensure pubsub message has been broadcast
      assert_receive {:user_removed_by_email, ^email}
      # Send message to liveview process to ensure liveview has processed pubsub message
      _ = :sys.get_state(view.pid)

      refute render(view) =~ "foo@example.com"
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
        |> live(~p"/retros/#{retro_id}/create_cards")

      assert view
             |> element("[data-test=\"remove-user-email-#{email}\"]")
             |> render_click() =~
               "Only the moderator can add and remove users"
    end
  end
end

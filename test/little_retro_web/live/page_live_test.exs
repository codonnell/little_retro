defmodule LittleRetroWeb.PageLiveTest do
  alias LittleRetro.Retros
  use LittleRetroWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import LittleRetro.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "homepage" do
    test "logged in user can create retro", %{conn: conn} do
      {:ok, view, _html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/")

      view |> element("#create-retro-button") |> render_click()

      # We don't know the uuid in advance, so catching the test failure message to do a regex match against it
      id =
        try do
          assert_redirect(view, "/")
        rescue
          e in ArgumentError ->
            captures =
              Regex.named_captures(
                ~r/got a redirect to "\/retros\/(?<id>[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[\w]{12})"/,
                e.message
              )

            refute is_nil(captures["id"])
            captures["id"]
        end

      refute is_nil(Retros.get(id))
    end

    test "redirects if user is not logged in", %{conn: conn} do
      {:error, redirect} = live(conn, ~p"/")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end
end

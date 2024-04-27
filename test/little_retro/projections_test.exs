defmodule LittleRetro.ProjectionsTest do
  alias LittleRetro.Retros.EventHandlers.RetroUsersProjection
  alias LittleRetro.Retros
  use LittleRetro.DataCase
  import LittleRetro.AccountsFixtures

  describe "retro_users_projection" do
    test "RetroCreated" do
      user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      projections = RetroUsersProjection |> Repo.all()

      assert [%{retro_id: retro_id, user_id: user.id, user_email: nil}] ==
               Enum.map(projections, &comparable/1)
    end

    test "UserAddedByEmail" do
      user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      Retros.add_user(retro_id, "me@example.com")
      projections = RetroUsersProjection |> Repo.all()

      assert MapSet.new([
               %{retro_id: retro_id, user_id: user.id, user_email: nil},
               %{retro_id: retro_id, user_id: nil, user_email: "me@example.com"}
             ]) == Enum.into(projections, MapSet.new(), &comparable/1)
    end

    test "UserRemovedByEmail" do
      user = user_fixture()
      {:ok, retro_id} = Retros.create_retro(user.id)
      Retros.add_user(retro_id, "me@example.com")
      Retros.remove_user(retro_id, "me@example.com")
      projections = RetroUsersProjection |> Repo.all()

      assert [%{retro_id: retro_id, user_id: user.id, user_email: nil}] ==
               Enum.map(projections, &comparable/1)
    end
  end

  defp comparable(projection) do
    projection |> Map.from_struct() |> Map.take([:retro_id, :user_id, :user_email])
  end
end

defmodule LittleRetro.RetrosFixtures do
  @moduledoc """
  This module defines test helpers for creating retros.
  """
  alias LittleRetro.Retros
  import LittleRetro.AccountsFixtures

  def retro_fixture(attrs \\ %{}) do
    {:ok, id} =
      if attrs[:moderator_id] do
        Retros.create_retro(attrs[:moderator_id])
      else
        user = user_fixture()
        Retros.create_retro(user.id)
      end

    id
  end
end

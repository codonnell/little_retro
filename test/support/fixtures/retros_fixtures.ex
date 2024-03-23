defmodule LittleRetro.RetrosFixtures do
  @moduledoc """
  This module defines test helpers for creating retros.
  """
  alias LittleRetro.Retros
  import LittleRetro.AccountsFixtures

  def retro_fixture(attrs \\ %{}) do
    moderator = attrs[:moderator] || user_fixture()
    {:ok, retro_id} = Retros.create_retro(moderator.id)
    %{retro_id: retro_id, user: moderator}
  end
end

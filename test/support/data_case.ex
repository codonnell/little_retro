defmodule LittleRetro.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use LittleRetro.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias LittleRetro.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import LittleRetro.DataCase
      import Commanded.Assertions.EventAssertions
    end
  end

  setup tags do
    setup_sandbox(tags)
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(LittleRetro.Repo, shared: not tags[:async])
    app = start_supervised!(LittleRetro.CommandedApplication)
    event_handlers = start_supervised!(LittleRetro.EventHandlerSupervisor)
    allow_recursive(self(), app)
    allow_recursive(self(), event_handlers)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  Allows all child process under passed in `app` to parent SQL sandbox pid
  """
  def allow_recursive(parent, app) do
    groups =
      Supervisor.which_children(app)
      |> Enum.group_by(fn {_, _, v, _} -> v end)

    Enum.each(Map.get(groups, :worker, []), fn {_, pid, _, _} ->
      Ecto.Adapters.SQL.Sandbox.allow(LittleRetro.Repo, parent, pid)
    end)

    Enum.each(Map.get(groups, :supervisor, []), fn {_, pid, _, _} ->
      Ecto.Adapters.SQL.Sandbox.allow(LittleRetro.Repo, parent, pid)
      allow_recursive(parent, pid)
    end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end

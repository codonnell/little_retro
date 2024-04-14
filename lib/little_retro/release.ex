defmodule LittleRetro.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :little_retro

  def migrate do
    load_app()

    for event_store <- event_stores() do
      config = event_store.config()

      EventStore.Tasks.Create.exec(config, quiet: true)
      EventStore.Tasks.Init.exec(config, quiet: true)
    end

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp event_stores do
    Application.fetch_env!(@app, :event_stores)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end

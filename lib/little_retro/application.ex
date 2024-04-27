defmodule LittleRetro.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LittleRetroWeb.Telemetry,
      LittleRetro.Repo,
      {DNSCluster, query: Application.get_env(:little_retro, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LittleRetro.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LittleRetro.Finch},
      # Start a worker by calling: LittleRetro.Worker.start_link(arg)
      # {LittleRetro.Worker, arg},
      LittleRetro.CommandedApplication,
      LittleRetro.EventHandlerSupervisor,
      # Start to serve requests, typically the last entry
      LittleRetroWeb.Endpoint
    ]

    children =
      if Application.get_env(:little_retro, :start_commanded) do
        children
      else
        Enum.reject(
          children,
          &(&1 in [LittleRetro.EventHandlerSupervisor, LittleRetro.CommandedApplication])
        )
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LittleRetro.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LittleRetroWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

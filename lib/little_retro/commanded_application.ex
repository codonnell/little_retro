defmodule LittleRetro.CommandedApplication do
  alias LittleRetro.Retros.Router

  use Commanded.Application,
    otp_app: :little_retro,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: LittleRetro.EventStore
    ]

  router(Router)
end

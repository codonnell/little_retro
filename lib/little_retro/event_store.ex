defmodule LittleRetro.EventStore do
  use EventStore, otp_app: :little_retro, schema: "event_store"
end

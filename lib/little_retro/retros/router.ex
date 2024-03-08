defmodule LittleRetro.Retros.Router do
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.CreateRetro
  use Commanded.Commands.Router

  dispatch(CreateRetro, to: Retro, identity: :id)
end

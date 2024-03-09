defmodule LittleRetro.Retros.Router do
  alias LittleRetro.Retros.Commands.RemoveUser
  alias LittleRetro.Retros.Commands.AddUser
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.CreateRetro
  use Commanded.Commands.Router

  identify(Retro, by: :id)

  dispatch(CreateRetro, to: Retro)
  dispatch(AddUser, to: Retro)
  dispatch(RemoveUser, to: Retro)
end

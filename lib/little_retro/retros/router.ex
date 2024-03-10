defmodule LittleRetro.Retros.Router do
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.CreateRetro
  use Commanded.Commands.Router

  identify(Retro, by: :id)

  dispatch(CreateRetro, to: Retro)
  dispatch(AddUserByEmail, to: Retro)
  dispatch(RemoveUserByEmail, to: Retro)
end

defmodule LittleRetro.Retros.Router do
  alias LittleRetro.Retros.Commands.VoteForCard
  alias LittleRetro.Retros.Commands.RemoveCardFromGroup
  alias LittleRetro.Retros.Commands.GroupCards
  alias LittleRetro.Retros.Commands.ChangePhase
  alias LittleRetro.Retros.Commands.DeleteCardById
  alias LittleRetro.Retros.Commands.EditCardText
  alias LittleRetro.Retros.Commands.CreateCard
  alias LittleRetro.Retros.Commands.RemoveUserByEmail
  alias LittleRetro.Retros.Commands.AddUserByEmail
  alias LittleRetro.Retros.Aggregates.Retro
  alias LittleRetro.Retros.Commands.CreateRetro
  use Commanded.Commands.Router

  identify(Retro, by: :retro_id)

  dispatch(
    [
      CreateRetro,
      AddUserByEmail,
      RemoveUserByEmail,
      CreateCard,
      EditCardText,
      DeleteCardById,
      ChangePhase,
      GroupCards,
      RemoveCardFromGroup,
      VoteForCard
    ],
    to: Retro
  )
end

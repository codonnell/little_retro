defmodule LittleRetroWeb.PageLive do
  require Logger
  alias LittleRetro.Retros
  use LittleRetroWeb, :live_view

  def render(assigns) do
    ~H"""
    <.button id="create-retro-button" phx-click="create_retro">Create Retro</.button>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("create_retro", _params, socket) do
    moderator_id = socket.assigns.current_user.id

    case Retros.create_retro(moderator_id) do
      {:ok, id} ->
        {:noreply, push_navigate(socket, to: "/retros/#{id}")}

      {:error, err} ->
        Logger.error("Failed to create retro: #{inspect(err)}")

        {:noreply,
         put_flash(
           socket,
           :error,
           "Failed to create retro. Please try again. If this continues, please contact support."
         )}
    end
  end
end

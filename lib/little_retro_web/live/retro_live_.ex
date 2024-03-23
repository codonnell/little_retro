defmodule LittleRetroWeb.RetroLive do
  require Logger
  alias Phoenix.PubSub
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias LittleRetro.Retros
  alias LittleRetroWeb.RetroUsers
  alias LittleRetroWeb.RetroComponents
  use LittleRetroWeb, :live_view

  def render(assigns) do
    assigns =
      assign(assigns, :is_moderator, assigns.current_user.id == assigns.retro.moderator_id)

    ~H"""
    <div class="h-screen flex flex-col">
      <RetroComponents.header is_moderator={@is_moderator} phase={@retro.phase} />
      <RetroUsers.retro_users_modal email_form={@email_form} user_emails={@retro.user_emails} />
      <div class="flex mt-8 divide-x-2 grow">
        <%= for column <- @retro.column_order |> Enum.map(& @retro.columns[&1]) do %>
          <div class="grow">
            <h3 class="text-xl font-bold text-center"><%= column.label %></h3>
            <div
              class="text-center mt-4"
              phx-click="create_card"
              phx-value-column-id={column.id}
              data-test={"create-card-column-#{column.id}"}
            >
              <.icon
                name="hero-plus-circle"
                class="h-8 w-8 cursor-pointer text-slate-500 hover:text-slate-700"
              />
            </div>
            <ul role="list" class="flex flex-wrap justify-center gap-6 m-4">
              <%= for card <- column.cards |> Enum.reverse() |> Enum.map(& @retro.cards[&1]) do %>
                <li class="divide-y" data-test={"card-list-item-#{card.id}"}>
                  <%= case @retro.phase do %>
                    <% :create_cards -> %>
                      <RetroComponents.editable_card
                        is_author={card.author_id == @current_user.id}
                        id={card.id}
                        text={card.text}
                        column_id={column.id}
                      />
                    <% _ -> %>
                      <div>Placeholder</div>
                  <% end %>
                </li>
              <% end %>
            </ul>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    retro = Retros.get(params["retro_id"])

    cond do
      user.id != retro.moderator_id and user.email not in retro.user_emails ->
        {:ok, redirect_unauthorized(socket)}

      true ->
        email_changeset = Accounts.change_user_email(%User{})
        PubSub.subscribe(LittleRetro.PubSub, "retro:#{retro.retro_id}")

        {:ok,
         socket
         |> assign(:retro, retro)
         |> assign(:email_form, to_form(email_changeset))
         |> assign(:latest_created_card_id, nil)}
    end
  end

  def handle_info({:retro_updated, retro}, socket) do
    {:noreply, assign(socket, :retro, retro)}
  end

  def handle_info({:card_created, %{retro: retro, card_id: card_id}}, socket) do
    socket = assign(socket, :retro, retro)

    socket =
      if retro.cards[card_id].author_id == socket.assigns.current_user.id do
        assign(socket, :latest_created_card_id, card_id)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("validate_email", %{"user" => user_params}, socket) do
    email_form =
      %User{}
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :email_form, email_form)}
  end

  def handle_event("add_email", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      email_form =
        case %User{}
             |> Accounts.change_user_email(user_params)
             |> Ecto.Changeset.apply_action(:update) do
          {:ok, %User{email: email}} ->
            Retros.add_user(retro.retro_id, email)
            %User{} |> Accounts.change_user_email() |> to_form()

          {:error, changeset} ->
            to_form(changeset)
        end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, email_form: email_form, retro: retro)}
    else
      {:noreply, put_flash(socket, :error, "Only the moderator can add and remove users")}
    end
  end

  def handle_event("remove_email", %{"email" => email}, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      Retros.remove_user(socket.assigns.retro.retro_id, email)
      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, :retro, retro)}
    else
      {:noreply, put_flash(socket, :error, "Only the moderator can add and remove users")}
    end
  end

  def handle_event("create_card", %{"column-id" => column_id}, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.create_card(retro.retro_id, %{
             author_id: user.id,
             column_id: String.to_integer(column_id)
           }) do
        {:error, err} -> Logger.error(err)
        _ -> nil
      end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, retro: retro)}
    else
      {:noreply, redirect_unauthorized(socket)}
    end
  end

  def handle_event("edit_card", %{"card-id" => card_id, "text" => text}, socket) do
    card_id = String.to_integer(card_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.edit_card_text(retro.retro_id, %{
             id: card_id,
             author_id: user.id,
             text: text
           }) do
        {:error, err} -> Logger.error(err)
        _ -> nil
      end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, retro: retro)}
    else
      {:noreply, redirect_unauthorized(socket)}
    end

    {:noreply, socket}
  end

  def handle_event("delete_card_by_id", %{"card-id" => card_id, "column-id" => column_id}, socket) do
    card_id = String.to_integer(card_id)
    column_id = String.to_integer(column_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.delete_card_by_id(retro.retro_id, %{
             id: card_id,
             author_id: user.id,
             column_id: column_id
           }) do
        {:error, err} -> Logger.error(err)
        _ -> nil
      end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, retro: retro)}
    else
      {:noreply, redirect_unauthorized(socket)}
    end

    {:noreply, socket}
  end

  def handle_event("change_phase", %{"to" => to}, socket) do
    to = String.to_existing_atom(to)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      Retros.change_phase(retro.retro_id, %{phase: to, user_id: user.id})
      retro = Retros.get(retro.retro_id)

      {:noreply,
       socket
       |> put_flash(
         :info,
         "A new phase dawns!"
       )
       |> assign(:retro, retro)}
    else
      {:noreply, put_flash(socket, :error, "Only the moderator can change phase.")}
    end
  end

  defp redirect_unauthorized(socket) do
    socket
    |> put_flash(
      :error,
      "You don't have access to this retro. Please ask the moderator to add your email."
    )
    |> push_navigate(to: ~p"/")
  end
end

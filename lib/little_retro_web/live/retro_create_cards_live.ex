defmodule LittleRetroWeb.RetroCreateCardsLive do
  require Logger
  alias Phoenix.PubSub
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias LittleRetro.Retros
  alias LittleRetroWeb.RetroUsers
  use LittleRetroWeb, :live_view

  def render(assigns) do
    assigns =
      assign(assigns, :is_moderator, assigns.current_user.id == assigns.retro.moderator_id)

    ~H"""
    <div class="h-screen flex flex-col">
      <div class="md:flex md:items-center md:justify-between">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Create Cards
          </h2>
        </div>
        <%= if @is_moderator do %>
          <div class="mt-4 flex md:ml-4 md:mt-0">
            <button
              type="button"
              class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
              data-test="open-users-modal-button"
              phx-click={show_modal("retro-users")}
            >
              Manage Users
            </button>
          </div>
        <% end %>
      </div>
      <RetroUsers.retro_users_modal email_form={@email_form} user_emails={@retro.user_emails} />
      <div class="flex mt-8 divide-x-2 grow">
        <%= for column <- @retro.column_order |> Enum.map(& @retro.columns[&1]) do %>
          <div class="grow">
            <h3 class="text-xl font-bold text-center"><%= column.label %></h3>
            <div class="text-center mt-4" phx-click="create_card" phx-value-column-id={column.id}>
              <.icon
                name="hero-plus-circle"
                class="h-8 w-8 cursor-pointer text-slate-500 hover:text-slate-700"
              />
            </div>
            <ul role="list" class="flex flex-wrap justify-center gap-6 m-4">
              <%= for card <- column.cards |> Enum.reverse() |> Enum.map(& @retro.cards[&1]) do %>
                <% is_author = card.author_id == @current_user.id %>
                <li class="divide-y">
                  <form phx-change="edit_card" phx-value-card-id={card.id} phx-debouce="1000">
                    <textarea
                      id="edit-card-textarea-#{card.id}"
                      phx-update={
                        if is_author do
                          "ignore"
                        else
                          "replace"
                        end
                      }
                      disabled={not is_author}
                      name="text"
                      maxlength="255"
                      x-data="{ resize: () => { $el.style.height = '5px'; $el.style.height = $el.scrollHeight + 'px' } }"
                      x-init="resize()"
                      @input="resize()"
                      class={"#{if is_author do "" else "blur-sm " end}block h-9 resize-none w-full rounded border-0 py-1.5 text-gray-900 shadow-lg ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"}
                    ><%= card.text %></textarea>
                  </form>
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

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      email_changeset = Accounts.change_user_email(%User{})
      PubSub.subscribe(LittleRetro.PubSub, "retro:#{retro.retro_id}")

      {:ok,
       socket
       |> assign(:retro, retro)
       |> assign(:email_form, to_form(email_changeset))
       |> assign(:latest_created_card_id, nil)}
    else
      {:ok, redirect_unauthorized(socket)}
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

      {:noreply, assign(socket, :email_form, email_form)}
    else
      {:noreply, put_flash(socket, :error, "Only the moderator can add and remove users")}
    end
  end

  def handle_event("remove_email", %{"email" => email}, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      Retros.remove_user(socket.assigns.retro.retro_id, email)
      {:noreply, socket}
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

      {:noreply, socket}
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

      {:noreply, socket}
    else
      {:noreply, redirect_unauthorized(socket)}
    end

    {:noreply, socket}
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

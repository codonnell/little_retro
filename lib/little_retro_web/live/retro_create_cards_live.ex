defmodule LittleRetroWeb.RetroCreateCardsLive do
  alias LittleRetro.Retros.Aggregates.Retro
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
        <div class="grow">
          <h3 class="text-xl font-bold text-center">Start</h3>
        </div>
        <div class="grow">
          <h3 class="text-xl font-bold text-center">Stop</h3>
        </div>
        <div class="grow">
          <h3 class="text-xl font-bold text-center">Continue</h3>
        </div>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    user = socket.assigns.current_user
    retro = Retros.get(params["retro_id"])

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      email_changeset = Accounts.change_user_email(%User{})
      PubSub.subscribe(LittleRetro.PubSub, "retro_users:#{retro.retro_id}")

      {:ok,
       socket
       |> assign(:retro, retro)
       |> assign(:email_form, to_form(email_changeset))}
    else
      {:ok,
       socket
       |> put_flash(
         :error,
         "You don't have access to this retro. Please ask the moderator to add your email."
       )
       |> push_navigate(to: ~p"/")}
    end
  end

  def handle_info({:user_added_by_email, email}, socket) do
    current_user_emails = socket.assigns.retro.user_emails

    user_emails =
      if email in current_user_emails do
        current_user_emails
      else
        [email | current_user_emails]
      end

    {:noreply, assign(socket, retro: %Retro{socket.assigns.retro | user_emails: user_emails})}
  end

  def handle_info({:user_removed_by_email, email}, socket) do
    user_emails =
      Enum.reject(socket.assigns.retro.user_emails, &(&1 == email))

    {:noreply, assign(socket, retro: %Retro{socket.assigns.retro | user_emails: user_emails})}
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
end

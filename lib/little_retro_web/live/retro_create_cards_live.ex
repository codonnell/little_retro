defmodule LittleRetroWeb.RetroCreateCardsLive do
  alias LittleRetro.Retros.Aggregates.Retro
  alias Phoenix.PubSub
  alias LittleRetro.Accounts
  alias LittleRetro.Accounts.User
  alias LittleRetro.Retros
  alias LittleRetroWeb.RetroUsers
  use LittleRetroWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <div class="md:flex md:items-center md:justify-between">
        <div class="min-w-0 flex-1">
          <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Create Cards
          </h2>
        </div>
        <div class="mt-4 flex md:ml-4 md:mt-0">
          <button
            type="button"
            class="inline-flex items-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50"
            phx-click={show_modal("retro-users")}
          >
            Manage Users
          </button>
        </div>
      </div>
      <RetroUsers.retro_users_modal email_form={@email_form} user_emails={@retro.user_emails} />
    </div>
    """
  end

  def mount(params, _session, socket) do
    retro = Retros.get(params["id"])
    email_changeset = Accounts.change_user_email(%User{})
    PubSub.subscribe(LittleRetro.PubSub, "retro_users:#{retro.id}")

    {:ok,
     socket
     |> assign(:retro, retro)
     |> assign(:email_form, to_form(email_changeset))}
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
    email_form =
      case %User{}
           |> Accounts.change_user_email(user_params)
           |> Ecto.Changeset.apply_action(:update) do
        {:ok, %User{email: email}} ->
          Retros.add_user(socket.assigns.retro.id, email)
          %User{} |> Accounts.change_user_email() |> to_form()

        {:error, changeset} ->
          to_form(changeset)
      end

    {:noreply, assign(socket, :email_form, email_form)}
  end

  def handle_event("remove_email", %{"email" => email}, socket) do
    Retros.remove_user(socket.assigns.retro.id, email)
    {:noreply, socket}
  end
end

defmodule LittleRetroWeb.RetroUsers do
  use LittleRetroWeb, :html

  attr :email_form, :map, required: true
  attr :user_emails, :list, required: true

  def retro_users_modal(assigns) do
    ~H"""
    <.modal id="retro-users">
      <h3>Users</h3>
      <div>
        <.simple_form
          for={@email_form}
          id="email-form"
          data-test="user-email-form"
          phx-submit="add_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <:actions>
            <.button phx-disable-with="Adding...">Add Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <p :if={Enum.count(@user_emails) == 0}>No users invited</p>
      <ul :if={Enum.count(@user_emails) > 0} role="list" class="divide-y divide-gray-200">
        <li :for={user_email <- Enum.reverse(@user_emails)} class="py-4">
          <span
            phx-click="remove_email"
            phx-value-email={user_email}
            data-test={"remove-user-email-#{user_email}"}
          >
            <.icon name="hero-x-mark" class="mr-1 text-red-600 cursor-pointer" />
          </span>
          <%= user_email %>
        </li>
      </ul>
    </.modal>
    """
  end
end

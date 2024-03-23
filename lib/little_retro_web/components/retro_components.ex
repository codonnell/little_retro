defmodule LittleRetroWeb.RetroComponents do
  alias LittleRetro.Retros
  use LittleRetroWeb, :html

  attr :is_moderator, :boolean, required: true
  attr :phase, :atom, required: true

  def header(assigns) do
    ~H"""
    <div class="md:flex md:items-center md:justify-between border-slate-300 border-b">
      <div class="min-w-0 flex-1 flex flex-row justify-evenly divide-x-2">
        <%= for phase <- Retros.phases() do %>
          <% selected = phase[:id] == @phase %>
          <div
            class={"py-3 px-6 grow text-center border-white rounded-t-md cursor-pointer transition ease-in-out #{if selected do "bg-slate-100" else "bg-slate-300 hover:bg-slate-200" end}"}
            phx-click="change_phase"
            phx-value-to={phase[:id]}
          >
            <%= phase[:label] %>
          </div>
        <% end %>
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
    """
  end
end

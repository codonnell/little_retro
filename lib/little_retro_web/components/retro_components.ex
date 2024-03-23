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
            data-test={"header-tab-#{phase[:id]}"}
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

  attr :is_author, :boolean, required: true
  attr :id, :integer, required: true
  attr :text, :string, required: true
  attr :column_id, :integer, required: true

  def editable_card(assigns) do
    ~H"""
    <form
      phx-change="edit_card"
      phx-value-card-id={@id}
      phx-debouce="1000"
      data-test={"edit-card-form-#{@id}"}
    >
      <span class="relative">
        <textarea
          id={"edit-card-textarea-#{@id}"}
          data-test={"edit-card-textarea-#{@id}"}
          phx-update={
            if @is_author do
              "ignore"
            else
              "replace"
            end
          }
          disabled={not @is_author}
          name="text"
          maxlength="255"
          x-data="{ resize: () => { $el.style.height = '4px'; $el.style.height = $el.scrollHeight + 'px' } }"
          x-init="resize()"
          @input="resize()"
          class={"#{if @is_author do "" else "blur-sm" end} block h-9 resize-none w-full rounded border-0 py-1.5 text-gray-900 shadow-lg ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"}
        ><%= @text %></textarea>
        <%= if @is_author do %>
          <span
            phx-click="delete_card_by_id"
            phx-value-card-id={@id}
            phx-value-column-id={@column_id}
            data-test={"delete-card-button-#{@id}"}
          >
            <.icon
              name="hero-trash"
              class="absolute h-4 w-4 top-0.5 right-0.5 text-red-200 cursor-pointer hover:text-red-400"
            />
          </span>
        <% end %>
      </span>
    </form>
    """
  end

  attr :id, :integer, required: true
  attr :text, :string, required: true
  attr :groups, :map, required: true
  attr :grouped_onto, :map, required: true

  def groupable_card(assigns) do
    ~H"""
    <div class="overflow-hidden rounded bg-white shadow-lg">
      <div class="px-3 py-1.5 w-52 min-h-9 h-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 sm:text-sm sm:leading-6">
        <%= @text %>
      </div>
    </div>
    """
  end
end

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
    <form phx-change="edit_card" phx-value-card-id={@id} data-test={"edit-card-form-#{@id}"}>
      <span class="relative">
        <textarea
          id={"edit-card-textarea-#{@id}"}
          data-test={"edit-card-textarea-#{@id}"}
          phx-debounce="1000"
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
  attr :cards, :map, required: true
  attr :groups, :map, required: true
  attr :grouped_onto, :map, required: true

  def groupable_card(assigns) do
    drag_target = Map.get(assigns.grouped_onto, assigns.id, :missing) in [assigns.id, :missing]

    assigns =
      assign(assigns,
        draggable: not Map.has_key?(assigns.grouped_onto, assigns.id),
        drag_target: drag_target,
        invisible: not drag_target,
        bottom_card: Map.has_key?(assigns.groups, assigns.id),
        card_group:
          if Map.has_key?(assigns.groups, assigns.id) do
            assigns.groups[assigns.id][:cards]
            |> Enum.map(fn id -> assigns.cards[id] end)
            |> Enum.reverse()
          end
      )

    ~H"""
    <%= if @bottom_card do %>
      <.expanded_card_group_modal cards={@card_group} include_remove_button={true} />
    <% end %>
    <div class="relative">
      <div
        class={"overflow-hidden rounded bg-white shadow-lg hover:shadow-xl hover:ring-1 ring-gray-300 #{if @invisible do "invisible" else "cursor-pointer" end}"}
        id={"groupable-card-#{@id}"}
        phx-hook="GroupableCard"
        phx-click={
          if @bottom_card do
            show_modal("expanded-card-group-modal-#{@id}")
          end
        }
        draggable={
          # draggable is an enumerated attribute, so it must be the string "true" or "false"
          if @draggable do
            "true"
          else
            "false"
          end
        }
        data-card-id={@id}
        data-dragtarget={@drag_target}
      >
        <div class="px-3 py-1.5 w-52 min-h-9 h-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 sm:text-sm sm:leading-6">
          <%= @text %>
        </div>
      </div>
      <%= if @bottom_card do %>
        <div class="overflow-hidden absolute -right-2 -top-2 -z-10 rounded bg-slate-100 shadow-lg">
          <div class="px-3 py-1.5 w-52 min-h-9 h-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 sm:text-sm sm:leading-6">
            <%= @text %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # TODO: Pass a more targeted set of attributes

  attr :id, :integer, required: true
  attr :cards, :map, required: true
  attr :groups, :map, required: true
  attr :grouped_onto, :map, required: true
  attr :votes, :list, required: true

  def voteable_card(assigns) do
    assigns =
      assign(assigns,
        bottom_card: Map.get(assigns.grouped_onto, assigns.id) == assigns.id,
        voteable: Map.get(assigns.grouped_onto, assigns.id, :missing) in [assigns.id, :missing],
        card_group:
          if Map.has_key?(assigns.groups, assigns.id) do
            assigns.groups[assigns.id][:cards]
            |> Enum.map(fn id -> assigns.cards[id] end)
            |> Enum.reverse()
          end
      )

    ~H"""
    <%= if @bottom_card do %>
      <.expanded_card_group_modal cards={@card_group} />
    <% end %>
    <div class="relative">
      <div class="absolute -top-6 flex space-x-1">
        <%= for {_, i} <- Enum.filter(@votes, & &1 == @id) |> Enum.with_index() do %>
          <span
            class="group"
            phx-click="remove_vote_from_card"
            phx-value-card-id={@id}
            data-test={"vote-circle-#{@id}-#{i}"}
          >
            <.icon
              name="hero-check-circle"
              class="h-4 w-4 text-blue-600 cursor-pointer group-hover:hidden"
            />
            <.icon
              name="hero-x-circle"
              class="h-4 w-4 text-red-500 cursor-pointer hidden group-hover:inline-block"
            />
          </span>
        <% end %>
      </div>
      <div class={"overflow-hidden rounded bg-white shadow-lg hover:shadow-xl hover:ring-1 ring-gray-300 #{if @voteable do "cursor-pointer" else "invisible" end}"}>
        <div
          class="px-3 py-1.5 w-52 min-h-9 h-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 sm:text-sm sm:leading-6"
          data-test={"voteable-card-#{@id}"}
          phx-click="vote_for_card"
          phx-value-card-id={@id}
        >
          <%= @cards[@id].text %>
        </div>
        <%= if @bottom_card do %>
          <span phx-click={show_modal("expanded-card-group-modal-#{@id}")}>
            <.icon
              name="hero-arrows-pointing-out"
              class="absolute h-4 w-4 top-0.5 right-0.5 text-slate-300 cursor-pointer hover:text-slate-500"
            />
          </span>
        <% end %>
      </div>
      <%= if @bottom_card do %>
        <div class="overflow-hidden absolute -right-2 -top-2 -z-10 rounded bg-slate-100 shadow-lg">
          <div class="px-3 py-1.5 w-52 min-h-9 h-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 sm:text-sm sm:leading-6">
            <%= @cards[@id].text %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :cards, :list, required: true
  attr :include_remove_button, :boolean, default: false

  def expanded_card_group_modal(assigns) do
    ~H"""
    <.modal id={"expanded-card-group-modal-#{hd(@cards).id}"}>
      <ul role="list" class="flex flex-wrap justify-center gap-6 m-4">
        <%= for card <- Enum.reverse(@cards) do %>
          <li id={"expanded-card-group-list-item-#{card.id}"} class="divide-y">
            <div class="relative overflow-hidden rounded bg-white shadow-lg">
              <div class="px-3 py-1.5 w-52 min-h-9 h-full border-0 text-gray-900 ring-1 ring-inset ring-gray-300 sm:text-sm sm:leading-6">
                <%= card.text %>
              </div>
              <%= if @include_remove_button do %>
                <span
                  phx-click={
                    JS.push("remove_card_from_group")
                    |> JS.add_class("hidden", to: "#expanded-card-group-list-item-#{card.id}")
                  }
                  phx-value-card-id={card.id}
                >
                  <.icon
                    name="hero-x-mark"
                    class="absolute h-4 w-4 top-0.5 right-0.5 text-red-200 cursor-pointer hover:text-red-400"
                  />
                </span>
              <% end %>
            </div>
          </li>
        <% end %>
      </ul>
    </.modal>
    """
  end
end

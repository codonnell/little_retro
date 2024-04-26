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
    retro = assigns.retro

    assigns =
      if retro.phase == :discussion and not Enum.empty?(retro.card_ids_to_discuss) do
        card_id = hd(retro.card_ids_to_discuss)
        IO.inspect(card_id)
        IO.inspect(retro.card_ids_to_discuss)
        IO.inspect(retro.votes_by_card_id)
        IO.inspect(retro.votes_by_card_id |> Map.get(card_id, []) |> Enum.count())

        card_ids =
          if Map.has_key?(retro.groups, card_id),
            do: retro.groups[card_id][:cards],
            else: [card_id]

        assign(assigns,
          cards_to_discuss: Enum.map(card_ids, fn id -> Map.get(retro.cards, id) end),
          num_votes: retro.votes_by_card_id |> Map.get(card_id, []) |> Enum.count()
        )
      else
        assigns
      end

    action_items =
      Map.keys(retro.action_items)
      |> Enum.sort()
      |> Enum.reverse()
      |> Enum.map(&Map.get(retro.action_items, &1))

    assigns =
      assign(assigns,
        is_moderator: assigns.current_user.id == retro.moderator_id,
        action_items: action_items
      )

    ~H"""
    <div class="grow flex flex-col">
      <RetroComponents.header is_moderator={@is_moderator} phase={@retro.phase} />
      <RetroUsers.retro_users_modal email_form={@email_form} user_emails={@retro.user_emails} />
      <%= if @retro.phase in [:create_cards, :group_cards, :vote] do %>
        <div class="flex mt-8 divide-x-2 grow h-full">
          <%= for column <- @retro.column_order |> Enum.map(& @retro.columns[&1]) do %>
            <div class="grow">
              <h3 class="text-xl font-bold text-center"><%= column.label %></h3>
              <%= if @retro.phase == :create_cards do %>
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
              <% end %>
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
                      <% :group_cards -> %>
                        <RetroComponents.groupable_card
                          id={card.id}
                          text={card.text}
                          cards={@retro.cards}
                          groups={@retro.groups}
                          grouped_onto={@retro.grouped_onto}
                        />
                      <% :vote -> %>
                        <RetroComponents.voteable_card
                          id={card.id}
                          cards={@retro.cards}
                          groups={@retro.groups}
                          grouped_onto={@retro.grouped_onto}
                          votes={Map.get(@retro.votes_by_user_id, @current_user.id, [])}
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
      <% else %>
        <div class="grow flex flex-row h-full">
          <span
            class={"p-1 self-center cursor-pointer border rounded-md border-gray-300 hover:bg-gray-50 text-gray-700 hover:text-gray-900 #{if Enum.empty?(@retro.card_ids_discussed) do "invisible" end}"}
            phx-click="move_discussion_back"
          >
            <.icon name="hero-arrow-left" class="h-12 w-12" />
          </span>
          <div class="grow flex flex-col mt-16 relative">
            <RetroComponents.cards_to_discuss_column
              num_votes={@num_votes}
              cards_to_discuss={@cards_to_discuss}
            />
          </div>
          <span
            class={"p-1 self-center cursor-pointer border rounded-md border-gray-300 hover:bg-gray-50 text-gray-700 hover:text-gray-900 #{if Enum.count(@retro.card_ids_to_discuss) < 2 do "invisible" end}"}
            phx-click="advance_discussion"
          >
            <.icon name="hero-arrow-right" class="h-12 w-12" />
          </span>
          <div class="mt-4 ml-8 pl-8 border-l-2">
            <RetroComponents.action_item_column
              action_items={@action_items}
              is_moderator={@is_moderator}
            />
          </div>
        </div>
      <% end %>
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

  def handle_info({:cards_grouped, %{card_id: card_id, retro: retro}}, socket) do
    {:noreply,
     socket
     |> assign(:retro, retro)
     |> push_event("cards_grouped", %{"card-id" => card_id})}
  end

  def handle_info({:card_removed_from_group, %{card_id: card_id, retro: retro}}, socket) do
    {:noreply,
     socket
     |> assign(:retro, retro)
     |> push_event("card_removed_from_group", %{"card-id" => card_id})}
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

  def handle_event("group_cards", %{"card-id" => card_id, "onto" => onto}, socket) do
    card_id = String.to_integer(card_id)
    onto = String.to_integer(onto)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.group_cards(retro.retro_id, %{
             card_id: card_id,
             user_id: user.id,
             onto: onto
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

  def handle_event("remove_card_from_group", %{"card-id" => card_id}, socket) do
    card_id = String.to_integer(card_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.remove_card_from_group(retro.retro_id, %{
             card_id: card_id,
             user_id: user.id
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

  def handle_event("vote_for_card", %{"card-id" => card_id}, socket) do
    card_id = String.to_integer(card_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.vote_for_card(retro.retro_id, %{
             card_id: card_id,
             user_id: user.id
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

  def handle_event("remove_vote_from_card", %{"card-id" => card_id}, socket) do
    card_id = String.to_integer(card_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id or user.email in retro.user_emails do
      case Retros.remove_vote_from_card(retro.retro_id, %{
             card_id: card_id,
             user_id: user.id
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

  def handle_event("create_action_item", _params, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      case Retros.create_action_item(retro.retro_id, %{author_id: user.id}) do
        {:error, err} -> Logger.error(err)
        _ -> nil
      end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, retro: retro)}
    else
      {:noreply, redirect_unauthorized(socket)}
    end
  end

  def handle_event(
        "edit_action_item",
        %{"action-item-id" => action_item_id, "text" => text},
        socket
      ) do
    action_item_id = String.to_integer(action_item_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      case Retros.edit_action_item_text(retro.retro_id, %{
             author_id: user.id,
             id: action_item_id,
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
  end

  # TODO: Make naming consistent between card and action item (delete vs. remove)
  def handle_event("delete_action_item_by_id", %{"action-item-id" => action_item_id}, socket) do
    action_item_id = String.to_integer(action_item_id)
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      case Retros.remove_action_item(retro.retro_id, %{
             author_id: user.id,
             id: action_item_id
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

  def handle_event("advance_discussion", _, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      case Retros.advance_discussion(retro.retro_id, %{user_id: user.id}) do
        {:error, err} -> Logger.error(err)
        _ -> nil
      end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, retro: retro)}
    else
      {:noreply, redirect_unauthorized(socket)}
    end
  end

  def handle_event("move_discussion_back", _, socket) do
    user = socket.assigns.current_user
    retro = socket.assigns.retro

    if user.id == retro.moderator_id do
      case Retros.move_discussion_back(retro.retro_id, %{user_id: user.id}) do
        {:error, err} -> Logger.error(err)
        _ -> nil
      end

      retro = Retros.get(retro.retro_id)
      {:noreply, assign(socket, retro: retro)}
    else
      {:noreply, redirect_unauthorized(socket)}
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

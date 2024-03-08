defmodule LittleRetroWeb.RetroCreateCardsLive do
  use LittleRetroWeb, :live_view

  def render(assigns) do
    ~H"""
    <h2>Create Cards</h2>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

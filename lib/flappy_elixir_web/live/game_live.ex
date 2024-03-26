defmodule FlappyElixirWeb.GameLive do
  use FlappyElixirWeb, :live_view

  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.YPosition

  def mount(_params, _session, socket) do
    socket =
      socket
      # TODO: is this needed?
      |> assign(player_entity: :player)
      # Keep a set of currently held keys to prevent duplicade keydown events
      |> assign(keys: MapSet.new())
      |> assign(x: 50, y: 50)

    # We don't want these calls to be made on both the initial static page render and again after
    # the LiveView is connected, so we wrap them in `connected?/1` to prevent duplication
    if connected?(socket) do
      ECSx.ClientEvents.add(:player, :spawn_player)
      :timer.send_interval(50, :load_player_info)
    end

    {:ok, socket}
  end

  def handle_info(:load_player_info, socket) do
    # Runs every 50ms to keep the client assigns updated
    x = XPosition.get(socket.assigns.player_entity)
    y = YPosition.get(socket.assigns.player_entity)

    {:noreply, assign(socket, x: x, y: y)}
  end

  def handle_event("keydown", %{"key" => key}, socket) do
    if MapSet.member?(socket.assigns.keys, key) do
      # Already holding this key - do nothing
      {:noreply, socket}
    else
      # We only want to add a client event if the key is defined by the `keydown/1` helper below
      maybe_add_client_event(socket.assigns.player_entity, key, &keydown/1)
      {:noreply, assign(socket, keys: MapSet.put(socket.assigns.keys, key))}
    end
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    # We don't have to worry about duplicate keyup events
    # But once again, we will only add client events for keys that actually do something
    maybe_add_client_event(socket.assigns.player_entity, key, &keyup/1)
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  # TODO: What does this do?
  defp maybe_add_client_event(player_entity, key, fun) do
    case fun.(key) do
      :noop -> :ok
      event -> ECSx.ClientEvents.add(player_entity, event)
    end
  end

  # TODO: Add Space key here!
  defp keydown(key) when key in ~w(w W ArrowUp), do: :jump
  defp keydown(_key), do: :noop

  # TODO: Add Space key here!
  # TODO: stop_jump might be needless
  # defp keyup(key) when key in ~w(w W ArrowUp), do: :stop_jump
  defp keyup(_key), do: :noop

  def render(assigns) do
    ~H"""
    <div id="game" phx-window-keydown="keydown" phx-window-keyup="keyup">
      <p>Player ID: <%= @player_entity %></p>
      
      <p>Player Coords: <%= inspect({@x, @y}) %></p>
    </div>
    """
  end
end

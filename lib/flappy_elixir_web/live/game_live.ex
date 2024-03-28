defmodule FlappyElixirWeb.GameLive do
  alias FlappyElixir.Components.PlayerSpawned
  use FlappyElixirWeb, :live_view

  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.ImageFile

  def mount(_params, _session, socket) do
    socket =
      socket
      # TODO: is this needed?
      |> assign(player_entity: :player)
      # Keep a set of currently held keys to prevent duplicate keydown events
      |> assign(keys: MapSet.new())
      |> assign(game_world_size: 160, screen_height: 160, screen_width: 90)
      |> assign_loading_state()

    # We don't want these calls to be made on both the initial static page render and again after
    # the LiveView is connected, so we wrap them in `connected?/1` to prevent duplication
    if connected?(socket) do
      ECSx.ClientEvents.add(:player, :spawn_player)
      send(self(), :first_load)
    end

    {:ok, socket}
  end

  defp assign_loading_state(socket) do
    assign(socket,
      x: nil,
      y: nil,
      loading: true,
      x_offset: 0,
      y_offset: 0,
      player_image_file: nil
    )
  end

  def handle_info(:first_load, socket) do
    # Do not start fetching components until after spawn is complete
    :ok = wait_for_spawn(socket.assigns.player_entity)

    socket =
      socket
      |> assign_player()
      |> assign_offsets()
      |> assign(loading: false)

    :timer.send_interval(50, :refresh)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign_player()
      |> assign_offsets()

    {:noreply, socket}
  end

  defp wait_for_spawn(player_entity) do
    if PlayerSpawned.exists?(player_entity) do
      :ok
    else
      Process.sleep(10)
      wait_for_spawn(player_entity)
    end
  end

  defp assign_player(socket) do
    x = XPosition.get(socket.assigns.player_entity)
    y = YPosition.get(socket.assigns.player_entity)
    image = ImageFile.get(socket.assigns.player_entity)

    assign(socket, x: x, y: y, player_image_file: image)
  end

  defp assign_offsets(socket) do
    # Note: the socket must already have updated player coordinates before assigning offsets!
    %{screen_width: screen_width, screen_height: screen_height} = socket.assigns
    %{x: x, y: y, game_world_size: game_world_size} = socket.assigns

    x_offset = calculate_offset(x, screen_width, game_world_size)
    y_offset = calculate_offset(y, screen_height, game_world_size)

    assign(socket, x_offset: x_offset, y_offset: y_offset)
  end

  defp calculate_offset(coord, screen_size, game_world_size) do
    case coord - div(screen_size, 2) do
      offset when offset < 0 -> 0
      offset when offset > game_world_size - screen_size -> game_world_size - screen_size
      offset -> offset
    end
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
    <div id="game" phx-window-keydown="keydown" phx-window-keyup="keyup" class="mx-auto h-screen">
      <svg
        viewBox={"#{@x_offset} #{@y_offset} #{@screen_width} #{@screen_height}"}
        preserveAspectRatio="xMinYMin slice"
        class="h-full pb-[56-25%] mx-auto"
      >
        <rect width={@game_world_size} height={@game_world_size} fill="#72eff8" />
        <%= if @loading do %>
          <text x={div(@screen_width, 2)} y={div(@screen_height, 2)} style="font: 1px serif">
            Loading...
          </text>
        <% else %>
          <image x={@x} y={@y} width="10" height="10" href={~p"/images/#{@player_image_file}"} />
          <text x={@x_offset} y={@y_offset + 4} style="font: 4px serif">
            Points: 0
          </text>
        <% end %>
      </svg>
    </div>
    """
  end
end

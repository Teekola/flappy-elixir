defmodule FlappyElixirWeb.GameLive do
  alias FlappyElixir.Components.CanRestart
  alias FlappyElixir.Components.GameRunning
  use FlappyElixirWeb, :live_view

  alias FlappyElixir.Components.PlayerSpawned
  alias FlappyElixir.Components.GameOver
  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.ImageFile
  alias FlappyElixir.Components.Pipe

  def mount(_params, _session, socket) do
    IO.puts(:mount)

    socket =
      socket
      |> assign(player_entity: :player)
      # Keep a set of currently held keys to prevent duplicate keydown events
      |> assign(keys: MapSet.new())
      # Define the relative size of the game world, 9:16 phone
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
      player_image_file: nil,
      pipes: []
    )
  end

  def handle_info(:first_load, socket) do
    IO.puts(:first_load)
    # Do not start fetching components until after spawn is complete
    if PlayerSpawned.exists?(socket.assigns.player_entity) do
      IO.puts("remove player")
      # PlayerSpawned.remove(socket.assigns.player_entity)
    end

    :ok = wait_for_spawn(socket.assigns.player_entity)

    socket =
      socket
      |> assign_player()
      |> assign_pipes()
      |> assign_offsets()
      |> assign(loading: false)

    :timer.send_interval(50, :refresh)

    {:noreply, socket}
  end

  def handle_info(:refresh, socket) do
    socket =
      socket
      |> assign_player()
      |> assign_pipes()
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
    x = 30
    y = YPosition.get(socket.assigns.player_entity)
    image = ImageFile.get(socket.assigns.player_entity)
    is_game_over = GameOver.exists?(socket.assigns.player_entity)
    is_game_running = GameRunning.exists?(socket.assigns.player_entity)
    can_restart = CanRestart.exists?(socket.assigns.player_entity)

    assign(socket,
      x: x,
      y: y,
      player_image_file: image,
      is_game_over: is_game_over,
      is_game_running: is_game_running,
      can_restart: can_restart
    )
  end

  defp assign_pipes(socket) do
    pipes =
      Enum.map(Pipe.get_all(), fn id ->
        %{x: XPosition.get(id), y: YPosition.get(id), img: ImageFile.get(id)}
      end)

    assign(socket, pipes: pipes)
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
    {:noreply, assign(socket, keys: MapSet.delete(socket.assigns.keys, key))}
  end

  defp maybe_add_client_event(player_entity, key, fun) do
    case fun.(key) do
      :noop -> :ok
      event -> ECSx.ClientEvents.add(player_entity, event)
    end
  end

  # Dispatch :jump event with the following keys (" " is Space)
  defp keydown(key) when key in [" ", "w", "W", "ArrowUp"] do
    is_game_running = GameRunning.exists?(:player)
    is_game_over = GameOver.exists?(:player)
    can_restart = CanRestart.exists?(:player)

    case {is_game_over, is_game_running, can_restart} do
      {_, true, _} ->
        :jump

      {true, _, true} ->
        :reset_game_state

      {false, false, _} ->
        :start_new_game

      _ ->
        :noop
    end
  end

  defp keydown(_key), do: :noop

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
          <text
            x={div(@screen_width, 2) + 5}
            y={div(@screen_height, 2) + 5}
            style="font: 10px sans-serif; text-anchor: middle;"
          >
            Loading...
          </text>
        <% else %>
          <%= if @is_game_over do %>
            <text
              x={div(@screen_width, 2) + 5}
              y={div(@screen_height, 2) + 5}
              style="font: 10px sans-serif; text-anchor: middle;"
            >
              Game Over!
            </text>
            
            <%= if @can_restart do %>
              <text
                x={div(@screen_width, 2) + 5}
                y={div(@screen_height, 2) + 15}
                style="font: 5px sans-serif; text-anchor: middle;"
              >
                Press Space
              </text>
            <% end %>
          <% else %>
            <%= unless @is_game_running do %>
              <text
                x={div(@screen_width, 2) + 5}
                y={div(@screen_height, 2) + 25}
                style="font: 8px sans-serif; text-anchor: middle;"
              >
                <tspan x={div(@screen_width, 2) + 5}>Press Space</tspan>
                
                <tspan x={div(@screen_width, 2) + 5} dy="1em">to Jump!</tspan>
              </text>
            <% end %>
          <% end %>
          
          <%= for pipe <- @pipes do %>
            <image x={pipe.x} y={pipe.y} width="15" href={~p"/images/#{pipe.img}"} />
          <% end %>
           <image x={@x} y={@y} width="10" height="10" href={~p"/images/#{@player_image_file}"} />
          <text x={@x_offset} y={@y_offset + 4} style="font: 4px sans-serif">
            Points: 0
          </text>
        <% end %>
      </svg>
    </div>
    """
  end
end

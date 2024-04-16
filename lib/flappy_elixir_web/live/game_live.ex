defmodule FlappyElixirWeb.GameLive do
  alias FlappyElixir.Components.Background
  alias FlappyElixir.Components.Points
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

    case Process.whereis(:game_live) do
      nil ->
        Process.register(self(), :game_live)

      _ ->
        Process.unregister(:game_live)
        Process.register(self(), :game_live)
    end

    socket =
      socket
      |> assign(player_entity: :player)
      # Keep a set of currently held keys to prevent duplicate keydown events
      |> assign(keys: MapSet.new())
      # Define the relative size of the game world, 9:16 phone
      |> assign(game_world_size: 160, screen_height: 160, screen_width: 90)
      |> assign_loading_state()
      |> assign_sounds()

    # We don't want these calls to be made on both the initial static page render and again after
    # the LiveView is connected, so we wrap them in `connected?/1` to prevent duplication
    if connected?(socket) do
      ECSx.ClientEvents.add(:player, :spawn_player)
      send(self(), :first_load)
    end

    {:ok, socket}
  end

  def terminate(_reason, _socket) do
    Process.unregister(:game_live)
    :ok
  end

  defp assign_loading_state(socket) do
    assign(socket,
      x: nil,
      y: nil,
      loading: true,
      x_offset: 0,
      y_offset: 0,
      player_image_file: nil,
      pipes: [],
      grounds: [],
      backgrounds: [],
      points: 0,
      high_score: 0
    )
  end

  defp assign_sounds(socket) do
    json =
      Jason.encode!(%{
        die: ~p"/audio/die.mp3",
        flap: ~p"/audio/flap.mp3",
        point: ~p"/audio/point.mp3",
        swoosh: ~p"/audio/swoosh.mp3"
      })

    assign(socket, :sounds, json)
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
      |> assign_backgrounds()
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
      |> assign_backgrounds()
      |> assign_offsets()

    {:noreply, socket}
  end

  def handle_info(:play_point, socket) do
    socket = socket |> push_event("play-sound", %{name: "point"})
    {:noreply, socket}
  end

  def handle_info(:play_die, socket) do
    socket = socket |> push_event("play-sound", %{name: "die"})
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
    points = Points.get(socket.assigns.player_entity)
    high_score = Points.get(:high_score)

    assign(socket,
      x: x,
      y: y,
      player_image_file: image,
      is_game_over: is_game_over,
      is_game_running: is_game_running,
      can_restart: can_restart,
      points: points,
      high_score: high_score
    )
  end

  defp assign_pipes(socket) do
    pipes =
      Enum.map(Pipe.get_all(), fn id ->
        %{x: XPosition.get(id), y: YPosition.get(id), img: ImageFile.get(id)}
      end)

    assign(socket, pipes: pipes)
  end

  defp assign_backgrounds(socket) do
    bgs =
      Enum.map(
        Enum.filter(Background.get_all(), fn id -> id !== :ground && id !== :ground2 end),
        fn id ->
          %{x: XPosition.get(id), y: YPosition.get(id), img: ImageFile.get(id)}
        end
      )

    grounds =
      Enum.map(
        Enum.filter(Background.get_all(), fn id -> id == :ground || id == :ground2 end),
        fn id ->
          %{x: XPosition.get(id), y: YPosition.get(id), img: ImageFile.get(id)}
        end
      )

    assign(socket, backgrounds: bgs, grounds: grounds)
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

      socket = socket |> push_event("play-sound", %{name: "flap"})

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
    <div
      id="game"
      phx-window-keydown="keydown"
      phx-window-keyup="keyup"
      phx-hook="AudioMp3"
      data-sounds={@sounds}
      class="mx-auto h-screen"
    >
      <.button
        style="position: absolute; left: 50%; translate:-50% 0; bottom: 2px;"
        phx-click={JS.dispatch("js:play-sound", detail: %{name: "swoosh"})}
      >
        Enable audio
      </.button>
      
      <svg
        viewBox={"#{@x_offset} #{@y_offset} #{@screen_width} #{@screen_height}"}
        preserveAspectRatio="xMinYMin slice"
        class="h-full pb-[56-25%] mx-auto"
      >
        <rect width={@game_world_size} height={@game_world_size} fill="#13103d" />
        <%= if @loading do %>
          <text
            x={div(@screen_width, 2) + 5}
            y={div(@screen_height, 2) + 5}
            style="font: 10px Titan One; text-anchor: middle;"
          >
            Loading...
          </text>
        <% else %>
          <%= for bg <- @backgrounds do %>
            <image x={bg.x} y={bg.y} width="90" href={~p"/images/#{bg.img}"} />
          <% end %>
          
          <%= for pipe <- @pipes do %>
            <image x={pipe.x} y={pipe.y} width="15" href={~p"/images/#{pipe.img}"} />
          <% end %>
          
          <%= for ground <- @grounds do %>
            <image x={ground.x} y={ground.y} width="90" href={~p"/images/#{ground.img}"} />
          <% end %>
           <image x={@x} y={@y} width="10" height="10" href={~p"/images/#{@player_image_file}"} />
          <%= if @is_game_over do %>
            <text
              x={div(@screen_width, 2) + 5}
              y={div(@screen_height, 2) + 5}
              style="font: 10px Titan One; text-anchor: middle; fill: white;"
            >
              Game Over!
            </text>
            
            <%= if @can_restart do %>
              <text
                x={div(@screen_width, 2) + 5}
                y={div(@screen_height, 2) + 15}
                style="font: 5px Titan One; text-anchor: middle; fill: white;"
              >
                Press Space
              </text>
            <% end %>
          <% else %>
            <%= unless @is_game_running do %>
              <text y={@y_offset + 48}>
                <tspan
                  x={div(@screen_width, 2)}
                  style="font: 6px Titan One; fill: white; text-anchor: middle;"
                >
                  High Score:
                </tspan>
                
                <tspan
                  x={div(@screen_width, 2)}
                  style="font: 6px Titan One; fill: white; text-anchor: middle;"
                  dy="1em"
                >
                  <%= @high_score %>
                </tspan>
              </text>
              
              <text
                x={div(@screen_width, 2)}
                y={div(@screen_height, 2) + 25}
                style="font: 8px Titan One; text-anchor: middle; fill: white;"
              >
                <tspan x={div(@screen_width, 2)}>Press Space</tspan>
                
                <tspan x={div(@screen_width, 2)} dy="1em">to Jump!</tspan>
              </text>
            <% end %>
          <% end %>
          
          <%= if @points !== @high_score do %>
            <text
              x={div(@screen_width, 2)}
              y={@y_offset + 16}
              style="font: 8px Titan One; fill: white"
            >
              <%= @points %>
            </text>
          <% else %>
            <text x={div(@screen_width, 2)} y={@y_offset + 16} style="font: 8px Titan One; fill: red;">
              <%= @high_score %>
            </text>
          <% end %>
        <% end %>
      </svg>
    </div>
    """
  end
end

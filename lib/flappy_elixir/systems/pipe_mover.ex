defmodule FlappyElixir.Systems.PipeMover do
  @moduledoc """
  Documentation for PipeMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.Points
  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.GameOver
  alias FlappyElixir.Components.GameRunning
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.XSpeed
  alias FlappyElixir.Components.Pipe

  @impl ECSx.System
  def run do
    if Pipe.exists?(:pipe1_top) && Pipe.exists?(:pipe1_bottom) do
      x_speed = XSpeed.get(:pipes)
      pipe1_x = XPosition.get(:pipe1_top)
      pipe1_x_new = pipe1_x + x_speed
      XPosition.update(:pipe1_top, pipe1_x_new)
      XPosition.update(:pipe1_bottom, pipe1_x_new)
      pipe2_x = XPosition.get(:pipe2_top)
      pipe2_x_new = pipe2_x + x_speed
      XPosition.update(:pipe2_top, pipe2_x_new)
      XPosition.update(:pipe2_bottom, pipe2_x_new)

      reposition(pipe1_x_new, :pipe1_top, :pipe1_bottom)
      reposition(pipe2_x_new, :pipe2_top, :pipe2_bottom)

      if GameRunning.exists?(:player) do
        check_player_collision(pipe1_x_new + 3.2, pipe2_x_new + 3.2)
      end
    end
  end

  defp reposition(pipe_x_new, top, bottom) do
    if pipe_x_new < -15.0 do
      min_height = -40.0
      max_height = 0.0
      top_height = :rand.uniform() * (max_height - min_height) + min_height
      bottom_height = top_height + 110.0
      XPosition.update(top, 90.0)
      XPosition.update(bottom, 90.0)
      YPosition.update(top, top_height)
      YPosition.update(bottom, bottom_height)
    end
  end

  defp check_player_collision(pipe1_x_left, pipe2_x_left) do
    pipe1_x_right = pipe1_x_left + 15.0 - 3.2
    pipe2_x_right = pipe2_x_left + 15.0 - 3.2
    pipe1_y_top = YPosition.get(:pipe1_top) + 80.0
    pipe1_y_bottom = YPosition.get(:pipe1_bottom)
    pipe2_y_top = YPosition.get(:pipe2_top) + 80.0
    pipe2_y_bottom = YPosition.get(:pipe2_bottom)

    player_x_left = 30
    player_x_right = player_x_left + 10.0
    player_y_top = YPosition.get(:player)
    player_y_bottom = player_y_top + 10.0

    update_points(pipe1_x_left, pipe2_x_left, player_x_right)

    # Pipe 1 collision pipes left side must be at least at the point of the player's right position
    # and pipes right side must be at least at the point of the player's left position
    if(player_x_right > pipe1_x_left && player_x_left < pipe1_x_right) do
      if(player_y_top < pipe1_y_top || player_y_bottom > pipe1_y_bottom) do
        game_over()
      end
    end

    # Pipe 1 collision pipes left side must be at least at the point of the player's right position
    # and pipes right side must be at least at the point of the player's left position
    if(player_x_right > pipe2_x_left && player_x_left < pipe2_x_right) do
      if(player_y_top < pipe2_y_top || player_y_bottom > pipe2_y_bottom) do
        game_over()
      end
    end
  end

  defp update_points(pipe1_x_left, pipe2_x_left, player_x_right) do
    if(
      (pipe1_x_left + 7.5 < player_x_right && pipe1_x_left + 7.5 > player_x_right - 1) ||
        (pipe2_x_left + 7.5 < player_x_right && pipe2_x_left + 7.5 > player_x_right - 1)
    ) do
      Points.update(:player, Points.get(:player) + 1)
    end
  end

  defp game_over() do
    GameOver.add(:player)
    GameRunning.remove(:player)
    XSpeed.update(:pipes, 0.0)

    # The manager.ex will receive this in handle_info method
    Process.send_after(self(), :add_can_restart, 1000)
  end
end

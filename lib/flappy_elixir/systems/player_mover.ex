defmodule FlappyElixir.Systems.PlayerMover do
  @moduledoc """
  Documentation for PlayerMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.XSpeed
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.YSpeed
  alias FlappyElixir.Components.GameOver
  alias FlappyElixir.Components.GameRunning

  @impl ECSx.System
  def run do
    case GameRunning.exists?(:player) do
      true ->
        # Update YPosition based on entity's YPosition and YSpeed
        y_speed = YSpeed.get(:player)
        y_position = YPosition.get(:player)
        new_y_position = y_position + y_speed
        handle_ground_collision(new_y_position)
        YPosition.update(:player, new_y_position)

        # Add YSpeed (gravity)
        prev_y_speed = YSpeed.get(:player)
        new_y_speed = prev_y_speed + Constants.get_gravity()
        YSpeed.update(:player, new_y_speed)

      _ ->
        :ok
    end
  end

  defp handle_ground_collision(new_y_position) do
    if new_y_position + 11 >= Constants.get_ground_y_position() do
      GameOver.add(:player)
      GameRunning.remove(:player)
      XSpeed.update(:pipes, 0.0)

      # The manager.ex will receive this in handle_info method
      Process.send_after(self(), :add_can_restart, 1000)
    end
  end
end

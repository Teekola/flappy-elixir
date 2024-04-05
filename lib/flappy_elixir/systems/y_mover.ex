defmodule FlappyElixir.Systems.YMover do
  @moduledoc """
  Documentation for YMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.CanRestart
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.YSpeed
  alias FlappyElixir.Components.GameOver
  alias FlappyElixir.Components.GameRunning

  @impl ECSx.System
  def run do
    case GameRunning.exists?(:player) do
      true ->
        for {entity, y_speed} <- YSpeed.get_all() do
          # Update YPosition based on entity's YPosition and YSpeed
          y_position = YPosition.get(entity)
          new_y_position = y_position + y_speed
          handle_ground_collision(new_y_position)
          YPosition.update(entity, new_y_position)

          # Add YSpeed (gravity)
          prev_y_speed = YSpeed.get(entity)
          new_y_speed = prev_y_speed + Constants.get_gravity()
          YSpeed.update(entity, new_y_speed)
        end

      _ ->
        :ok
    end
  end

  defp handle_ground_collision(new_y_position) do
    if new_y_position >= Constants.get_ground_y_position() do
      GameOver.add(:player)
      GameRunning.remove(:player)

      # The manager.ex will receive this in handle_info method
      Process.send_after(self(), :add_can_restart, 1000)
    end
  end
end

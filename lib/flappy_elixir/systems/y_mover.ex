defmodule FlappyElixir.Systems.YMover do
  @moduledoc """
  Documentation for YMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.YSpeed
  alias FlappyElixir.Components.GameRunning

  @impl ECSx.System
  def run do
    case GameRunning.exists?(:player) do
      true ->
        for {entity, y_speed} <- YSpeed.get_all() do
          # Update YPosition based on entity's YPosition and YSpeed
          y_position = YPosition.get(entity)
          new_y_position = y_position + y_speed
          handleGroundCollision(new_y_position)
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

  defp handleGroundCollision(new_y_position) do
    if new_y_position >= Constants.get_ground_y_position() do
      GameRunning.remove(:player)
    end
  end
end

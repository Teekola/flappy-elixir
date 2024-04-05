defmodule FlappyElixir.Systems.YMover do
  @moduledoc """
  Documentation for YMover system.
  """
  @behaviour ECSx.System
  @gravity 0.1

  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.YSpeed

  @impl ECSx.System
  def run do
    for {entity, y_speed} <- YSpeed.get_all() do
      # Update YPosition based on entity's YPosition and YSpeed
      y_position = YPosition.get(entity)
      new_y_position = y_position + y_speed
      YPosition.update(entity, new_y_position)

      # Add YSpeed (gravity)
      prev_y_speed = YSpeed.get(entity)
      new_y_speed = prev_y_speed + @gravity
      YSpeed.update(entity, new_y_speed)
    end
  end
end

defmodule FlappyElixir.Systems.YMover do
  @moduledoc """
  Documentation for YMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.YSpeed

  @impl ECSx.System
  def run do
    # Update YPosition based on entity's YPosition and YSpeed
    for {entity, y_speed} <- YSpeed.get_all() do
      y_position = YPosition.get(entity)
      new_y_position = y_position + y_speed
      YPosition.update(entity, new_y_position)
    end
  end
end

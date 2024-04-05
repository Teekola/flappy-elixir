defmodule FlappyElixir.Systems.XMover do
  @moduledoc """
  Documentation for XMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.XSpeed

  @impl ECSx.System
  def run do
    # Update XPosition based on entity's XPosition and XSpeed
    for {entity, x_position} <- XPosition.get_all() do
      x_speed = XSpeed.get(:pipes)
      new_x_position = x_position + x_speed
      XPosition.update(entity, new_x_position)
      destroy_outside_screen(entity, new_x_position)
    end
  end

  defp destroy_outside_screen(entity, new_x_position) do
    if new_x_position < 20 do
      XPosition.update(entity, 180)
    end
  end

  # Todo: handle player collision here as well!
end

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
    for {entity, x_speed} <- XSpeed.get_all() do
      x_position = XPosition.get(entity)
      new_x_position = x_position + x_speed
      XPosition.update(entity, new_x_position)
    end
  end
end

defmodule FlappyElixir.Systems.BackgroundMover do
  @moduledoc """
  Documentation for BackgroundMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.GameOver
  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.XSpeed

  @impl ECSx.System
  def run do
    unless GameOver.exists?(:player) do
      ground_speed = XSpeed.get(:ground)
      ground_x = XPosition.get(:ground)
      ground_x_new = ground_x + ground_speed
      ground2_x = XPosition.get(:ground2)
      ground2_x_new = ground2_x + ground_speed
      reposition(:ground, ground_x_new)
      reposition(:ground2, ground2_x_new)
      mountain_speed = XSpeed.get(:mountains)
      mountains_x = XPosition.get(:mountains)
      mountains_x_new = mountains_x + mountain_speed
      mountains2_x = XPosition.get(:mountains2)
      mountains2_x_new = mountains2_x + mountain_speed
      reposition(:mountains, mountains_x_new)
      reposition(:mountains2, mountains2_x_new)
    end
  end

  defp reposition(entity, x_new) do
    if x_new < -89 do
      XPosition.update(entity, 89.5)
    else
      XPosition.update(entity, x_new)
    end
  end
end

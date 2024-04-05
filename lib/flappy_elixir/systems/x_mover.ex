defmodule FlappyElixir.Systems.XMover do
  @moduledoc """
  Documentation for XMover system.
  """
  @behaviour ECSx.System

  alias FlappyElixir.Components.XPosition
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

      if pipe1_x_new < -25 do
        reposition(:pipe1_top, :pipe1_bottom)
      end
    end
  end

  defp reposition(top, bottom) do
    min_height = -30
    max_height = 30
    top_height = :rand.uniform() * (max_height - min_height) + min_height
    bottom_height = top_height + 110
    XPosition.update(top, 100)
    XPosition.update(bottom, 100)
    YPosition.update(top, top_height)
    YPosition.update(bottom, bottom_height)
  end
end

# Todo: handle player collision here as well!

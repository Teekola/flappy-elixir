defmodule FlappyElixir.Systems.PipeMover do
  @moduledoc """
  Documentation for PipeMover system.
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
      pipe2_x = XPosition.get(:pipe2_top)
      pipe2_x_new = pipe2_x + x_speed
      XPosition.update(:pipe2_top, pipe2_x_new)
      XPosition.update(:pipe2_bottom, pipe2_x_new)

      reposition(pipe1_x_new, :pipe1_top, :pipe1_bottom)
      reposition(pipe2_x_new, :pipe2_top, :pipe2_bottom)
    end
  end

  defp reposition(pipe_x_new, top, bottom) do
    if pipe_x_new < -15 do
      min_height = -40
      max_height = 0
      top_height = :rand.uniform() * (max_height - min_height) + min_height
      bottom_height = top_height + 110
      XPosition.update(top, 90.0)
      XPosition.update(bottom, 90.0)
      YPosition.update(top, top_height)
      YPosition.update(bottom, bottom_height)
    end
  end
end

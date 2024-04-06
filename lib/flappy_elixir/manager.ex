defmodule FlappyElixir.Manager do
  @moduledoc """
  ECSx manager.
  """
  use ECSx.Manager

  def setup do
    # Seed persistent components only for the first server start
    # (This will not be run on subsequent app restarts)
    :ok
  end

  def startup do
    # Load ephemeral components during first server start and again
    # on every subsequent app restart
    :ok
  end

  # Declare all valid Component types
  def components do
    [
      FlappyElixir.Components.Points,
      FlappyElixir.Components.Pipe,
      FlappyElixir.Components.CanRestart,
      FlappyElixir.Components.GameOver,
      FlappyElixir.Components.GameRunning,
      FlappyElixir.Components.ImageFile,
      FlappyElixir.Components.PlayerSpawned,
      FlappyElixir.Components.YSpeed,
      FlappyElixir.Components.XSpeed,
      FlappyElixir.Components.XPosition,
      FlappyElixir.Components.YPosition
    ]
  end

  # Declare all Systems to run
  def systems do
    [
      FlappyElixir.Systems.ClientEventHandler,
      FlappyElixir.Systems.PipeMover,
      FlappyElixir.Systems.PlayerMover
    ]
  end

  def handle_info(:add_can_restart, state) do
    FlappyElixir.Components.CanRestart.add(:player)
    {:noreply, state}
  end

  def handle_info(:reset_player_img, state) do
    FlappyElixir.Components.ImageFile.update(:player, "player.svg")
    {:noreply, state}
  end

  def handle_info(:spawn_pipes, state) do
    min_height = -40
    max_height = 0
    top_height = :rand.uniform() * (max_height - min_height) + min_height
    bottom_height = top_height + 110

    FlappyElixir.Components.Pipe.add(:pipe1_top)
    FlappyElixir.Components.ImageFile.add(:pipe1_top, "pipe-top.svg")
    FlappyElixir.Components.XPosition.add(:pipe1_top, 90.0)
    FlappyElixir.Components.YPosition.add(:pipe1_top, top_height)
    FlappyElixir.Components.Pipe.add(:pipe1_bottom)
    FlappyElixir.Components.ImageFile.add(:pipe1_bottom, "pipe-bottom.svg")
    FlappyElixir.Components.XPosition.add(:pipe1_bottom, 90.0)
    FlappyElixir.Components.YPosition.add(:pipe1_bottom, bottom_height)

    min_height = -40
    max_height = 0
    top_height = :rand.uniform() * (max_height - min_height) + min_height
    bottom_height = top_height + 110

    FlappyElixir.Components.Pipe.add(:pipe2_top)
    FlappyElixir.Components.ImageFile.add(:pipe2_top, "pipe-top.svg")
    FlappyElixir.Components.XPosition.add(:pipe2_top, 142.5)
    FlappyElixir.Components.YPosition.add(:pipe2_top, top_height)
    FlappyElixir.Components.Pipe.add(:pipe2_bottom)
    FlappyElixir.Components.ImageFile.add(:pipe2_bottom, "pipe-bottom.svg")
    FlappyElixir.Components.XPosition.add(:pipe2_bottom, 142.5)
    FlappyElixir.Components.YPosition.add(:pipe2_bottom, bottom_height)

    {:noreply, state}
  end
end

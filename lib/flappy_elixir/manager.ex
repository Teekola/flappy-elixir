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
      FlappyElixir.Systems.XMover,
      FlappyElixir.Systems.YMover
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
end

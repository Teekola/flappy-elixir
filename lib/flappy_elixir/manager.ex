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

    # player = %{id: :player, x: 50, y: 50, gravity: 1}

    # # Create player with Position and YSpeed components
    # FlappyElixir.Components.XPosition.add(player.id, player.x)
    # FlappyElixir.Components.YPosition.add(player.id, player.y)
    # FlappyElixir.Components.YSpeed.add(player.id, player.gravity)
  end

  # Declare all valid Component types
  def components do
    [
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
end

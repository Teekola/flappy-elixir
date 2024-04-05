defmodule FlappyElixir.Systems.ClientEventHandler do
  @moduledoc """
  Documentation for ClientEventHandler system.
  """
  alias FlappyElixir.Components.ImageFile
  alias FlappyElixir.Components.PlayerSpawned
  alias FlappyElixir.Components.YSpeed
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.GameRunning
  @behaviour ECSx.System

  @impl ECSx.System
  def run do
    client_events = ECSx.ClientEvents.get_and_clear()

    Enum.each(client_events, &process_one/1)
  end

  defp process_one({player, :spawn_player}) do
    if PlayerSpawned.exists?(player) do
      XPosition.update(player, 50)
      YPosition.update(player, 50.0)
      YSpeed.update(player, 0.0)
    else
      PlayerSpawned.add(player)
      XPosition.add(player, 50)
      YPosition.add(player, 50.0)
      YSpeed.add(player, 0.1)
      ImageFile.add(player, "player.svg")
    end
  end

  defp process_one({player, :jump}) do
    unless GameRunning.exists?(player) do
      GameRunning.add(player)
    end

    YSpeed.update(player, -Constants.get_jump_speed())
  end
end

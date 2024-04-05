defmodule FlappyElixir.Systems.ClientEventHandler do
  @moduledoc """
  Documentation for ClientEventHandler system.
  """
  alias FlappyElixir.Components.CanRestart
  alias FlappyElixir.Components.GameRunning
  alias FlappyElixir.Components.ImageFile
  alias FlappyElixir.Components.PlayerSpawned
  alias FlappyElixir.Components.YSpeed
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.XPosition
  alias FlappyElixir.Components.GameOver
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
      YSpeed.add(player, 0.0)
      ImageFile.add(player, "player.svg")
    end
  end

  defp process_one({player, :jump}) do
    YSpeed.update(player, -Constants.get_jump_speed())
    ImageFile.update(player, "player-jump.svg")
    # FlappyElixir.Manager handles this in handle_info
    Process.send_after(self(), :reset_player_img, 150)
  end

  defp process_one({player, :reset_game_state}) do
    GameOver.remove(player)
    YPosition.update(player, 50.0)
    YSpeed.update(player, 0.0)
  end

  defp process_one({player, :start_new_game}) do
    GameRunning.add(player)
    CanRestart.remove(player)
  end
end

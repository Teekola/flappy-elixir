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
  alias FlappyElixir.Components.XSpeed
  alias FlappyElixir.Components.GameOver
  @behaviour ECSx.System

  @impl ECSx.System
  def run do
    client_events = ECSx.ClientEvents.get_and_clear()

    Enum.each(client_events, &process_one/1)
  end

  defp process_one({player, :spawn_player}) do
    if PlayerSpawned.exists?(player) do
      YPosition.update(player, 80.0)
      YSpeed.update(player, 0.0)
      XSpeed.update(:pipes, 0)
    else
      PlayerSpawned.add(player)
      YPosition.add(player, 80.0)
      YSpeed.add(player, 0.0)
      ImageFile.add(player, "player.svg")
      XSpeed.add(:pipes, 0)
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
    YPosition.update(player, 80.0)
    YSpeed.update(player, 0.0)
    XSpeed.update(:pipes, 0)

    FlappyElixir.Components.Pipe.remove(:pipe1_top)
    FlappyElixir.Components.ImageFile.remove(:pipe1_top)
    FlappyElixir.Components.XPosition.remove(:pipe1_top)
    FlappyElixir.Components.YPosition.remove(:pipe1_top)
    FlappyElixir.Components.Pipe.remove(:pipe1_bottom)
    FlappyElixir.Components.ImageFile.remove(:pipe1_bottom)
    FlappyElixir.Components.XPosition.remove(:pipe1_bottom)
    FlappyElixir.Components.YPosition.remove(:pipe1_bottom)
  end

  defp process_one({player, :start_new_game}) do
    GameRunning.add(player)
    CanRestart.remove(player)
    XSpeed.update(:pipes, -1)

    :timer.send_after(1000, :spawn_pipes)
  end
end

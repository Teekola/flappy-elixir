defmodule FlappyElixir.Systems.ClientEventHandler do
  @moduledoc """
  Documentation for ClientEventHandler system.
  """
  alias FlappyElixir.Components.PlayerSpawned
  alias FlappyElixir.Components.YSpeed
  alias FlappyElixir.Components.YPosition
  alias FlappyElixir.Components.XPosition
  @behaviour ECSx.System

  @impl ECSx.System
  def run do
    client_events = ECSx.ClientEvents.get_and_clear()

    Enum.each(client_events, &process_one/1)
  end

  defp process_one({player, :spawn_player}) do
    XPosition.add(player, 50)
    YPosition.add(player, 50)
    YSpeed.add(player, 1)
    PlayerSpawned.add(player)
  end

  defp process_one({player, :jump}) do
    YSpeed.update(player, -10)
  end
end

defmodule GeoPong.GameInstances do
  alias GeoPong.{GameInstanceDynamicSupervisor, GameInstanceRegistry}
  alias GeoPong.GameInstances.{GameInstance, GameInstanceProcess}

  def all do
    GameInstanceDynamicSupervisor.all_game_instance_pids()
    |> Enum.reduce([], fn pid, acc ->
      case fetch(pid) do
        %GameInstance{} = game_instance -> [game_instance | acc]
        _ -> acc
      end
    end)
  end

  def fetch(game_instance_pid) when is_pid(game_instance_pid) do
    game_instance_pid
    |> GameInstanceProcess.fetch()
    |> case do
      %GameInstance{} = game_instance -> game_instance
      _ -> {:error, :not_found}
    end
  end

  def fetch(game_instance_id) do
    game_instance_id
    |> GameInstanceRegistry.lookup_game_instance()
    |> case do
      {:ok, pid} -> GameInstanceProcess.fetch(pid)
      error -> error
    end
  end
end
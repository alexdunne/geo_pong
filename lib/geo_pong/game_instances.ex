defmodule GeoPong.GameInstances do
  require Logger

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

  def create() do
    Logger.info("Creating a new game instance")

    instance = GameInstance.new()

    Logger.info("New game created [id: #{instance.id}]")

    GameInstanceDynamicSupervisor.add_game_instance_to_supervisor(instance)

    instance
  end

  def join(instance_id) do
    Logger.info("Attempting to join game instance #{instance_id}")

    instance_id
    |> GameInstanceRegistry.lookup_game_instance()
    |> case do
      {:ok, pid} -> GameInstanceProcess.join(pid)
      error -> error
    end
  end

  def mark_player_as_ready(instance_id, player_id) do
    Logger.info("Attempting to mark a player as ready #{instance_id}")

    instance_id
    |> GameInstanceRegistry.lookup_game_instance()
    |> case do
      {:ok, pid} -> GameInstanceProcess.mark_player_as_ready(pid, player_id)
      error -> error
    end
  end
end

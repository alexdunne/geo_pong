defmodule GeoPong.GameInstances.GameInstanceProcess do
  import GeoPong.GameInstances.GameInstance, only: [is_game_full: 1]

  use GenServer, restart: :transient

  require Logger

  alias GeoPong.GameInstances.{GameInstance, Player}

  def start_link(%GameInstance{} = game_instance) do
    GenServer.start_link(__MODULE__, game_instance,
      name: {:via, Registry, {GeoPong.GameInstanceRegistry, game_instance.id}}
    )
  end

  @impl true
  def init(%GameInstance{} = game_instance) do
    {:ok, game_instance}
  end

  # Client API

  def fetch(pid) do
    pid
    |> GenServer.call(:fetch)
  end

  def join(pid) do
    pid
    |> GenServer.call(:join)
  end

  # Callbacks

  @impl true
  def handle_call(:fetch, _from, %GameInstance{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:join, _from, %GameInstance{} = state) do
    case add_new_player(state) do
      {:ok, %GameInstance{} = instance, %Player{} = player} ->
        {:reply, {:ok, instance, player}, instance}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  defp add_new_player(%GameInstance{players: players}) when is_game_full(players) do
    {:error, :game_full}
  end

  defp add_new_player(%GameInstance{} = game_instance) do
    player = Player.new()
    instance = %{game_instance | players: game_instance.players ++ [player]}

    {:ok, instance, player}
  end
end

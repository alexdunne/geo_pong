defmodule GeoPong.GameInstances.GameInstanceProcess do
  use GenServer, restart: :transient

  require Logger

  alias GeoPong.GameInstances.{Ball, GameEngine, GameInstance, Player}
  alias GeoPongWeb

  @tick_interval 16
  # 10 minutes
  @max_process_duration 600_000

  def start_link(%GameInstance{} = game_instance) do
    GenServer.start_link(__MODULE__, game_instance,
      name: {:via, Registry, {GeoPong.GameInstanceRegistry, game_instance.id}}
    )
  end

  @impl true
  def init(%GameInstance{} = game_instance) do
    tick()
    terminate_after(@max_process_duration)

    Logger.info("Initialising a new game instance")

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

  def mark_player_as_ready(pid, player_id) do
    pid
    |> GenServer.cast({:mark_player_as_ready, player_id})
  end

  def handle_player_action(pid, player_id, action) do
    pid
    |> GenServer.cast({:handle_player_action, player_id, action})
  end

  # Callbacks

  @impl true
  def handle_call(:fetch, _from, %GameInstance{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:join, _from, %GameInstance{} = state) do
    case GameInstance.add_new_player(state) do
      {:ok, %GameInstance{} = instance, %Player{} = player} ->
        {:reply, {:ok, instance, player}, instance}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  @impl true
  def handle_cast({:mark_player_as_ready, player_id}, state) do
    send(self(), :after_player_marked_as_ready)

    {:noreply, GameInstance.mark_player_as_ready(state, player_id)}
  end

  @impl true
  def handle_cast({:handle_player_action, player_id, action}, state) do
    {:noreply, GameInstance.handle_player_action(state, player_id, action)}
  end

  @impl true
  def handle_info(:after_player_marked_as_ready, state) do
    state.players
    |> GameInstance.all_players_ready?()
    |> case do
      true ->
        {:noreply, GameInstance.start_countdown(state)}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:tick, %GameInstance{status: :countdown_in_progress} = state) do
    state =
      state
      |> GameInstance.countdown_elapsed?()
      |> case do
        true -> GameInstance.start_game(state)
        _ -> state
      end

    broadcast_game_state(state)
    tick()

    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, %GameInstance{status: :game_in_progress} = state) do
    state =
      state
      |> GameInstance.game_over?()
      |> case do
        true ->
          send(self(), {:end_game})
          GameInstance.end_game(state)

        _ ->
          GameEngine.run(state)
      end

    broadcast_game_state(state)
    tick()

    {:noreply, state}
  end

  @impl true
  def handle_info(:tick, state) do
    broadcast_game_state(state)
    tick()

    {:noreply, state}
  end

  @impl true
  def handle_info({:broadcast, event, message}, %GameInstance{} = state) do
    GeoPongWeb.Endpoint.broadcast_from!(self(), "game:#{state.id}", event, message)

    {:noreply, state}
  end

  @impl true
  def handle_info({:end_game}, state) do
    Logger.info("Terminating game instance")

    Process.exit(self(), :normal)
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp game_view(%GameInstance{} = instance) do
    %{
      id: instance.id,
      status: instance.status,
      gameStartTime: instance.game_start_time,
      gameEndTime: instance.game_end_time,
      players: Enum.map(instance.players, fn player -> player_view(player) end),
      ball: ball_view(instance.ball),
      score: instance.score,
      engine: %{
        playerSize: GameEngine.player_size(),
        gameHeight: GameEngine.game_height(),
        gameWidth: GameEngine.game_width(),
        ballSize: GameEngine.ball_size()
      }
    }
  end

  defp player_view(%Player{} = player) do
    %{
      name: player.name,
      ready: player.ready,
      position: player.position
    }
  end

  defp ball_view(%Ball{} = ball) do
    %{
      x: ball.x,
      y: ball.y
    }
  end

  # Internal commands

  defp tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp terminate_after(duration) do
    Process.send_after(self(), {:end_game}, duration)
  end

  defp broadcast_game_state(state) do
    send(self(), {:broadcast, "game_state", game_view(state)})
  end
end

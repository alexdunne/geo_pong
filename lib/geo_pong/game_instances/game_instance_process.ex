defmodule GeoPong.GameInstances.GameInstanceProcess do
  use GenServer, restart: :transient

  require Logger

  alias GeoPong.GameInstances.{GameInstance, Player}
  alias GeoPongWeb

  def start_link(%GameInstance{} = game_instance) do
    GenServer.start_link(__MODULE__, game_instance,
      name: {:via, Registry, {GeoPong.GameInstanceRegistry, game_instance.id}}
    )
  end

  @impl true
  def init(%GameInstance{} = game_instance) do
    tick()

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

  # Game loop

  def handle_info(:tick, %GameInstance{status: :countdown_in_progress} = state) do
    state =
      state
      |> GameInstance.countdown_elapsed?()
      |> case do
        true ->
          GameInstance.start_game(state)

        _ ->
          state
      end

    send(self(), {:broadcast, "game_state", state})
    tick()

    {:noreply, state}
  end

  def handle_info(:tick, %GameInstance{status: :game_in_progress} = state) do
    state =
      state
      |> GameInstance.game_over?()
      |> case do
        true ->
          GameInstance.end_game(state)
          game_over()

        _ ->
          state
      end

    send(self(), {:broadcast, "game_state", state})
    tick()

    {:noreply, state}
  end

  def handle_info(:tick, state) do
    send(self(), {:broadcast, "game_state", state})
    tick()

    {:noreply, state}
  end

  @impl true
  def handle_info({:broadcast, event, message}, state) do
    GeoPongWeb.Endpoint.broadcast_from!(self(), "game:#{state.id}", event, message)

    {:noreply, state}
  end

  # Internal commands

  defp tick do
    Process.send_after(self(), :tick, 16)
  end

  defp game_over do
    Process.exit(self(), :game_over)
  end
end

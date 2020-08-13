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
    schedule_broadcast_to_subscribers()

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
        send(self(), {:broadcast, "all_players_ready", %{}})
        {:noreply, GameInstance.update_status(state, GameInstance.status_all_players_ready())}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info(:broadcast_to_subscribers, state) do
    send(self(), {:broadcast, "game_state", %{}})
    schedule_broadcast_to_subscribers()

    {:noreply, state}
  end

  @impl true
  def handle_info({:broadcast, event, message}, state) do
    GeoPongWeb.Endpoint.broadcast_from!(self(), "game:#{state.id}", event, message)

    {:noreply, state}
  end

  # Internal commands

  defp schedule_broadcast_to_subscribers do
    Process.send_after(self(), :broadcast_to_subscribers, 16)
  end
end

defmodule GeoPongWeb.GameChannel do
  use Phoenix.Channel

  require Logger

  alias GeoPong.GameInstances
  alias GeoPong.GameInstances.{GameInstance, Player}

  def join("game:" <> topic, payload, socket) do
    Logger.info("Attempting to connect to channel game:#{topic}")

    do_join(["game"] ++ String.split(topic, ":"), payload, socket)
  end

  def handle_in("new_player_action", %{"action" => action}, socket) do
    socket.topic
    |> get_game_instance_id()
    |> GameInstances.handle_player_action(socket.assigns[:player_id], action)

    {:noreply, socket}
  end

  # Player specific channel
  defp do_join(["game", game_instance_id, "player"], _payload, socket) do
    game_instance_id
    |> fetch_game_player(socket.assigns.player_id)
    |> case do
      {:ok, _} ->
        send(self(), {:after_player_join, game_instance_id})
        {:ok, socket}

      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  # General game information channel
  defp do_join(["game", _game_instance_id], _payload, socket) do
    {:ok, socket}
  end

  def handle_info({:after_player_join, game_instance_id}, socket) do
    GameInstances.mark_player_as_ready(game_instance_id, socket.assigns.player_id)

    {:noreply, socket}
  end

  defp fetch_game_player(game_instance_id, player_id) do
    with %GameInstance{} = instance <- GameInstances.fetch(game_instance_id),
         %Player{} = player <- GameInstance.find_player_by_id(instance, player_id) do
      {:ok, player}
    else
      _ -> {:error, :player_not_found}
    end
  end

  defp get_game_instance_id(topic) do
    [_, id, _] = String.split(topic, ":")

    id
  end
end

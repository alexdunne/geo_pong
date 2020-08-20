defmodule GeoPong.GameInstances.GameEngine do
  alias GeoPong.GameInstances.{GameInstance, Player}

  @game_width 600
  @game_height 400

  @player_size %{width: 10, height: 100}
  @player_x_padding 10
  @player_move_increment 10

  @countdown_duration_seconds 3
  @game_duration_seconds 300

  def game_width, do: @game_width
  def game_height, do: @game_height
  def player_size, do: @player_size
  def countdown_duration_seconds, do: @countdown_duration_seconds
  def game_duration_seconds, do: @game_duration_seconds

  def next_player_position(%GameInstance{players: players}) do
    x =
      case Enum.empty?(players) do
        # First player
        true -> @player_x_padding
        # Second player
        _ -> @game_width - @player_size.width - @player_x_padding
      end

    %{x: x, y: @game_height / 2 - @player_size.height / 2}
  end

  def run(%GameInstance{} = instance) do
    players =
      instance.players
      |> Enum.map(&move_player(&1))

    %{instance | players: players}
  end

  defp move_player(%Player{current_action: action} = player) when action == :idle do
    player
  end

  defp move_player(%Player{current_action: action} = player) when action == :left_down do
    next_y = max(player.position.y - @player_move_increment, 0)

    put_in(player.position.y, next_y)
  end

  defp move_player(%Player{current_action: action} = player) when action == :right_down do
    next_y =
      case player.position.y + @player_move_increment + @player_size.height > @game_height do
        true -> @game_height - @player_size.height
        _ -> player.position.y + @player_move_increment
      end

    put_in(player.position.y, next_y)
  end
end

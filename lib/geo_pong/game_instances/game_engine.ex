defmodule GeoPong.GameInstances.GameEngine do
  alias GeoPong.GameInstances.{Ball, GameInstance, Player}

  @game_width 600
  @game_height 400

  @player_size %{width: 10, height: 100}
  @player_x_padding 10
  @player_move_increment 10

  @ball_size 20

  @countdown_duration_seconds 3
  @game_duration_seconds 300

  def game_width, do: @game_width
  def game_height, do: @game_height
  def player_size, do: @player_size
  def ball_size, do: @ball_size
  def countdown_duration_seconds, do: @countdown_duration_seconds
  def game_duration_seconds, do: @game_duration_seconds

  def calculate_player_initial_position(is_first_player) when is_first_player == true do
    %{x: @player_x_padding, y: @game_height / 2 - @player_size.height / 2}
  end

  def calculate_player_initial_position(_) do
    %{
      x: @game_width - @player_size.width - @player_x_padding,
      y: @game_height / 2 - @player_size.height / 2
    }
  end

  def create_ball() do
    Ball.new(%{
      x: @game_width / 2 - @ball_size / 2,
      y: @game_height / 2 - @ball_size / 2,
      x_speed: :rand.uniform(15),
      y_speed: :rand.uniform(15)
    })
  end

  def run(%GameInstance{} = instance) do
    instance =
      instance
      |> move_players()
      |> move_ball()

    cond do
      has_player_scored(instance, :player_one) ->
        instance
        |> GameInstance.increment_player_score(:player_one)
        |> reset_entity_positions()

      has_player_scored(instance, :player_two) ->
        instance
        |> GameInstance.increment_player_score(:player_two)
        |> reset_entity_positions()

      true ->
        process_collisions(instance)
    end
  end

  def reset_entity_positions(%GameInstance{ball: ball, players: players} = instance) do
    players =
      players
      |> Enum.with_index()
      |> Enum.map(fn {player, idx} ->
        position = calculate_player_initial_position(idx == 0)

        Map.put(player, :position, position)
      end)

    %{instance | ball: create_ball(), players: players}
  end

  defp move_players(%GameInstance{players: players} = instance) do
    players =
      players
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

  defp move_ball(%GameInstance{ball: ball} = instance) do
    ball =
      ball
      |> Map.put(:x, ball.x + ball.x_speed)
      |> Map.put(:y, ball.y + ball.y_speed)

    %{instance | ball: ball}
  end

  defp has_player_scored(%GameInstance{ball: ball}, :player_one) do
    ball.x + ball_radius() > @game_width
  end

  defp has_player_scored(%GameInstance{ball: ball}, :player_two) do
    ball.x < ball_radius()
  end

  defp process_collisions(%GameInstance{} = instance) do
    instance
    # What if there is a player and a boundary collision?
    |> process_player_collisions()
    |> process_boundary_collision()
  end

  defp process_player_collisions(%GameInstance{ball: ball} = instance) do
    if is_player_collision(instance) do
      ball =
        ball
        |> Map.put(:x_speed, ball.x_speed * -1)

      %{instance | ball: ball}
    else
      instance
    end
  end

  defp is_player_collision(%GameInstance{} = instance) do
    is_collision_with_player_one(instance) || is_collision_with_player_two(instance)
  end

  defp is_collision_with_player_one(%GameInstance{ball: ball, players: players}) do
    player = List.first(players)

    ball_left = ball.x - ball_radius()
    player_right = player.position.x + @player_size.width

    is_horizontal_collision = ball_left <= player_right

    is_horizontal_collision && is_vertical_collision_with_player(player, ball)
  end

  defp is_collision_with_player_two(%GameInstance{ball: ball, players: players}) do
    player = List.last(players)

    ball_right = ball.x + ball_radius()
    player_left = player.position.x

    is_horizontal_collision = ball_right >= player_left

    is_horizontal_collision && is_vertical_collision_with_player(player, ball)
  end

  defp is_vertical_collision_with_player(%Player{} = player, %Ball{} = ball) do
    player_top = player.position.y
    player_bottom = player.position.y + @player_size.height

    ball_top = ball.y - ball_radius()
    ball_bottom = ball.y + ball_radius()

    ball_top <= player_bottom && ball_bottom >= player_top
  end

  defp process_boundary_collision(%GameInstance{ball: ball} = instance) do
    y_speed =
      case is_y_boundary_collision?(ball) do
        true -> ball.y_speed * -1
        _ -> ball.y_speed
      end

    ball =
      ball
      |> Map.put(:y_speed, y_speed)

    %{instance | ball: ball}
  end

  defp is_y_boundary_collision?(%Ball{} = ball) do
    ball.y < ball_radius() || ball.y + ball_radius() > @game_height
  end

  defp ball_radius do
    @ball_size / 2
  end
end

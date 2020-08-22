defmodule GeoPong.GameInstances.GameInstance do
  alias GeoPong.GameInstances.{GameEngine, GameInstance, Player}

  require Logger

  @enforce_keys [:id, :status, :players, :ball, :score]
  @derive {Jason.Encoder, only: [:id, :status, :game_start_time, :game_end_time, :score]}
  defstruct [:id, :status, :game_start_time, :game_end_time, :players, :ball, :score]

  defguard is_game_full(players) when length(players) >= 2

  def new do
    id = generate_id()

    %GameInstance{
      id: id,
      status: status_waiting_for_players(),
      players: [],
      ball: GameEngine.create_ball(),
      score: [0, 0]
    }
  end

  def status_waiting_for_players, do: :waiting_for_players
  def status_countdown_in_progress, do: :countdown_in_progress
  def status_game_in_progress, do: :game_in_progress
  def status_game_over, do: :game_over

  def find_player_by_id(%GameInstance{players: players}, player_id) do
    players
    |> Enum.find(fn player -> player.id == player_id end)
  end

  def add_new_player(%GameInstance{players: players}) when is_game_full(players) do
    {:error, :game_full}
  end

  def add_new_player(%GameInstance{players: players} = game_instance) do
    is_first_player = length(players) == 0

    player =
      Player.new(%{
        initial_position: GameEngine.calculate_player_initial_position(is_first_player)
      })

    instance = %{game_instance | players: game_instance.players ++ [player]}

    {:ok, instance, player}
  end

  def mark_player_as_ready(%GameInstance{} = game_instance, player_id) do
    players =
      game_instance.players
      |> Enum.map(fn player ->
        case player.id == player_id do
          true -> %{player | ready: true}
          _ -> player
        end
      end)

    %{game_instance | players: players}
  end

  def all_players_ready?(players) when is_game_full(players) do
    Enum.all?(players, fn player -> player.ready == true end)
  end

  def all_players_ready?(_players) do
    false
  end

  def start_countdown(%GameInstance{} = game_instance) do
    game_instance
    |> update_status(status_countdown_in_progress())
    |> Map.put(:game_start_time, generate_start_time())
  end

  def countdown_elapsed?(%GameInstance{
        status: :countdown_in_progress,
        game_start_time: game_start_time
      }) do
    Timex.after?(Timex.now(), game_start_time)
  end

  def countdown_elapsed?(_instance) do
    false
  end

  def start_game(%GameInstance{} = game_instance) do
    game_instance
    |> update_status(status_game_in_progress())
    |> Map.put(:game_end_time, generate_end_time())
  end

  def game_over?(%GameInstance{status: :game_in_progress, game_end_time: game_end_time}) do
    Timex.after?(Timex.now(), game_end_time)
  end

  def game_over?(_instance) do
    false
  end

  def end_game(%GameInstance{} = game_instance) do
    game_instance
    |> update_status(status_game_over())
  end

  def handle_player_action(
        %GameInstance{status: :game_in_progress} = game_instance,
        player_id,
        action
      ) do
    players =
      game_instance.players
      |> Enum.map(fn player ->
        case player.id == player_id do
          true -> Player.handle_action(player, action)
          _ -> player
        end
      end)

    %{game_instance | players: players}
  end

  def handle_player_action(%GameInstance{} = game_instance, _player_id, _action) do
    game_instance
  end

  def player_scored(%GameInstance{} = instance, :player_one) do
    instance =
      instance
      |> increment_player_score(:player_one)
      |> GameEngine.reset_entity_positions()
  end

  def player_scored(%GameInstance{} = instance, :player_two) do
    instance =
      instance
      |> increment_player_score(:player_one)
      |> GameEngine.reset_entity_positions()
  end

  def increment_player_score(%GameInstance{score: score} = instance, :player_one) do
    %{instance | score: List.update_at(score, 0, &(&1 + 1))}
  end

  def increment_player_score(%GameInstance{score: score} = instance, :player_two) do
    %{instance | score: List.update_at(score, 1, &(&1 + 1))}
  end

  defp generate_id do
    first = Faker.Superhero.prefix()
    second = Faker.Commerce.color()
    third = Faker.Food.ingredient()

    "#{first}-#{second}-#{third}"
    |> String.downcase()
    |> String.replace(" ", "-")
  end

  defp update_status(%GameInstance{} = game_instance, status) do
    %{game_instance | status: status}
  end

  defp generate_start_time() do
    Timex.shift(Timex.now(), seconds: GameEngine.countdown_duration_seconds())
  end

  defp generate_end_time() do
    Timex.shift(Timex.now(), seconds: GameEngine.game_duration_seconds())
  end
end

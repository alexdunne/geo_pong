defmodule GeoPong.GameInstances.GameInstance do
  alias GeoPong.GameInstances.{GameInstance, Player}

  @enforce_keys [:id, :status, :players]
  @derive {Jason.Encoder, only: [:id, :status, :game_start_time]}
  defstruct [:id, :status, :game_start_time, :players]

  defguard is_game_full(players) when length(players) >= 2

  def new do
    id = generate_id()

    %GameInstance{
      id: id,
      status: status_waiting_for_players(),
      players: []
    }
  end

  def status_waiting_for_players, do: :waiting_for_players
  def status_countdown_in_progress, do: :countdown_in_progress
  def status_game_in_progress, do: :game_in_progress

  def find_player_by_id(%GameInstance{players: players}, player_id) do
    players
    |> Enum.find(fn player -> player.id == player_id end)
  end

  def add_new_player(%GameInstance{players: players}) when is_game_full(players) do
    {:error, :game_full}
  end

  def add_new_player(%GameInstance{} = game_instance) do
    player = Player.new()
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
    |> set_game_start_time()
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

  defp set_game_start_time(%GameInstance{} = game_instance) do
    %{game_instance | game_start_time: Timex.shift(Timex.now(), seconds: 3)}
  end
end

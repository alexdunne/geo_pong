defmodule GeoPong.GameInstances.GameInstance do
  alias GeoPong.GameInstances.{GameInstance, Player}

  @enforce_keys [:id, :status, :players]
  @derive {Jason.Encoder, only: [:id, :status]}
  defstruct [:id, :status, :players]

  defguard is_game_full(players) when length(players) >= 2

  def new do
    id = generate_id()

    %GameInstance{
      id: id,
      status: status_waiting_for_players_to_join(),
      players: []
    }
  end

  def status_waiting_for_players_to_join, do: :waiting_for_players_to_join
  def status_all_players_ready, do: :all_players_ready

  def update_status(%GameInstance{} = game_instance, status) do
    %{game_instance | status: status}
  end

  def find_player_by_id(%GameInstance{} = game_instance, player_id) do
    game_instance
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

  defp generate_id do
    first = Faker.Superhero.prefix()
    second = Faker.Commerce.color()
    third = Faker.Food.ingredient()

    "#{first}-#{second}-#{third}"
    |> String.downcase()
    |> String.replace(" ", "-")
  end
end

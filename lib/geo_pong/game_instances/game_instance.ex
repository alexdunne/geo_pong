defmodule GeoPong.GameInstances.GameInstance do
  alias GeoPong.GameInstances.{GameInstance}

  @enforce_keys [:id, :secret]
  @derive {Jason.Encoder, only: [:id]}
  defstruct [:id, :secret, :players]

  defguard is_game_full(players) when length(players) >= 2

  def new do
    id = generate_id()

    %GameInstance{
      id: id,
      secret: UUID.uuid4(),
      players: []
    }
  end

  def get_player_one(%GameInstance{} = game_instance) do
    hd(game_instance.players)
  end

  def get_player_two(%GameInstance{} = game_instance) do
    List.last(game_instance.players)
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

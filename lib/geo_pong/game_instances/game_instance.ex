defmodule GeoPong.GameInstances.GameInstance do
  @enforce_keys [:id, :code]
  @derive Jason.Encoder
  defstruct [:id, :code]

  def new() do
    %GeoPong.GameInstances.GameInstance{
      id: UUID.uuid4(),
      code: generate_code()
    }
  end

  defp generate_code do
    first = Faker.Superhero.prefix()
    second = Faker.Commerce.color()
    third = Faker.Food.ingredient()

    String.downcase("#{first} #{second} #{third}")
  end
end

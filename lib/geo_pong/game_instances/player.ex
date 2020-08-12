defmodule GeoPong.GameInstances.Player do
  @enforce_keys [:id, :name]
  @derive {Jason.Encoder, only: [:name]}
  defstruct [:id, :name]

  def new do
    %GeoPong.GameInstances.Player{
      id: UUID.uuid4(),
      name: generate_name()
    }
  end

  defp generate_name do
    title = Faker.Superhero.prefix()
    team = Faker.Team.creature()

    String.downcase("#{title} #{team}")
  end
end

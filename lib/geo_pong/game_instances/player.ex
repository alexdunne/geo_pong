defmodule GeoPong.GameInstances.Player do
  @enforce_keys [:id, :name, :ready]
  @derive {Jason.Encoder, only: [:name, :ready]}
  defstruct [:id, :name, :ready]

  def new do
    %GeoPong.GameInstances.Player{
      id: UUID.uuid4(),
      name: generate_name(),
      ready: false
    }
  end

  defp generate_name do
    title = Faker.Superhero.prefix()
    team = Faker.Team.creature()

    String.downcase("#{title} #{team}")
  end
end

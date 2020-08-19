defmodule GeoPong.GameInstances.Player do
  alias GeoPong.GameInstances.Player

  @enforce_keys [:id, :name, :ready, :current_action, :position]
  @derive {Jason.Encoder, only: [:name, :ready, :position]}
  defstruct [:id, :name, :ready, :current_action, :position]

  def new(%{initial_position: initial_position}) do
    %Player{
      id: UUID.uuid4(),
      name: generate_name(),
      ready: false,
      current_action: :idle,
      position: initial_position
    }
  end

  def action_idle, do: :idle
  def action_left_down, do: :left_down
  def action_right_down, do: :right_down

  def handle_action(%Player{} = player, "left_button_pressed") do
    %{player | current_action: action_left_down}
  end

  def handle_action(%Player{} = player, "left_button_released") do
    %{player | current_action: action_idle}
  end

  def handle_action(%Player{} = player, "right_button_pressed") do
    %{player | current_action: action_right_down}
  end

  def handle_action(%Player{} = player, "right_button_released") do
    %{player | current_action: action_idle}
  end

  defp generate_name do
    title = Faker.Superhero.prefix()
    team = Faker.Team.creature()

    String.downcase("#{title} #{team}")
  end
end

defimpl String.Chars, for: GeoPong.GameInstances.Player do
  def to_string(player) do
    string =
      "name: #{player.name}, ready: #{player.ready}, x: #{player.position.x}, y: #{
        player.position.y
      }, current_action: #{player.current_action}"

    "{#{string}}"
  end
end
